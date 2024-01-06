/*
  Generate a dynamic insert JSON statement for a table using short or long name.
  Schema is optional, it can be found using library list and QTEMP.

  Examples:
    call bolib.generate_insert_json('TABLE101','');         
    call bolib.generate_insert_json('TABLE101','','QTEMP'); 
    call bolib.generate_insert_json('TABLE101','','SOMESCHEMA');
    call bolib.generate_insert_json('SOMETHING','');         
    call bolib.generate_insert_json('LONG_NAME_ALIAS','');
    call bolib.generate_insert_json('LONG_NAME_ALIAS','','QTEMP');
    call bolib.generate_insert_json('LONG_NAME_ALIAS','','SOMESCHEMA'); 
    call bolib.generate_insert_json('SHORTNAME','');
    call bolib.generate_insert_json('SHORTNAME','','QTEMP');
    call bolib.generate_insert_json('SHORTNAME','','SOMESCHEMA');


    create table QTEMP.TABLE2(col1 char(2), col2 int, col3 varchar(8));
    CL: RMVLIBLE LIB(QTEMP); 
    CL: ADDLIBLE LIB(QTEMP) POSITION(*FIRST);
    call bolib.generate_insert_json('TABLE','');
    call bolib.generate_insert_json('TABLE2','');
    CL: RMVLIBLE LIB(QTEMP);
    CL: ADDLIBLE LIB(QTEMP) POSITION(*LAST); 
    call bolib.generate_insert_json('TABLE2','','SOMESCHEMA');
    drop table QTEMP.TABLE2;


  Generates (I manually formatted it):

  -- call generate_insert_json('TABLE101');  (QTEMP is top of LIBL)
  INSERT INTO QTEMP.TABLE101(COL1, COL2, COL3, COL4, COL5) 
  SELECT * FROM JSON_TABLE(?, '$.TABLE101[*]' COLUMNS (
    COL1 CHAR (4) PATH 'lax $.COL1', 
    COL2 CHAR (6) PATH 'lax $.COL2', 
    COL3 DECIMAL (3,0) PATH 'lax $.COL3', 
    COL4 CHAR (7) PATH 'lax $.COL4', 
    COL5 DECIMAL (4,0) PATH 'lax $.COL5', 
  ) ERROR ON ERROR)

  
  Usage in a procedure:

  declare ins_stmt VARCHAR(20000); -- Dynamic SQL insert statement
  call GENERATE_INSERT_JSON(UPPER(some_var), ins_stmt);                      
  if length(ins_stmt) > 0 then
    PREPARE S1 FROM ins_stmt; 
    EXECUTE S1 USING in_JSON; 
  end if;   

*/

create or replace procedure BOLIB/GENERATE_INSERT_JSON ( 
  in  in_table  varchar(128),
  out sql_str   varchar(20000),
  in  in_schema varchar(128) default ''
)
  LANGUAGE SQL 
  SPECIFIC BOLIB/GENINSJSON
  SET OPTION DBGVIEW = *SOURCE,
             DLYPRP  = *YES

begin
  declare command               varchar(512);
  declare target_schema         varchar(128);
  declare target_table          varchar(128);
  declare use_qtemp             smallint default 1;
  declare target_schema_ordinal smallint; 
  
  declare cond_notfound         condition for sqlstate '42704';
  declare qtemp_cursor          cursor for qtemp_stmt;
  
  declare continue handler for cond_notfound
    begin
      set use_qtemp=0;
    end;
  
  
  -- If schema given, don't worry about use_qtemp logic below
  set use_qtemp = (
    case 
      when upper(trim(in_schema)) in ('QTEMP','') then 1
      else 0
    end
  );
  
  -- Find schema from LIBL to get table description
  set target_schema = (
    case
      when upper(trim(in_schema)) in ('QTEMP','') then (
        -- find schema from LIBL and user provided table
        select                                   
          TABLE_SCHEMA
        from QSYS2.SYSTABLES a
         left outer join QSYS2.LIBRARY_LIST_INFO b
           on a.TABLE_SCHEMA=b.SCHEMA_NAME
        where b.TYPE='USER' 
          and (a.TABLE_NAME=in_table 
            or a.SYSTEM_TABLE_NAME=in_table)
        order by b.ordinal_position
        limit 1
      )
      else in_schema -- otherwise, use provided schema
    end
  );
  
  -- Store target_schema's ordinal position for QTEMP compare
  set target_schema_ordinal = (           
    select 
      ORDINAL_POSITION               
    from QSYS2.LIBRARY_LIST_INFO          
    where TYPE='USER'                     
      and SYSTEM_SCHEMA_NAME=target_schema
    limit 1                               
  );
                                        
  -- Find table short name, otherwise assumed short
  set target_table = coalesce(                     
    (select 
       coalesce(BASE_TABLE_NAME, SYSTEM_TABLE_NAME)
     from QSYS2.SYSTABLES                          
       where TABLE_SCHEMA=target_schema 
         and (TABLE_NAME=in_table  
           or SYSTEM_TABLE_NAME=in_table)
       and TABLE_SCHEMA=target_schema              
     limit 1),                                   
    in_table                                      
  );
  
  -- Check if table in QTEMP, set use_qtemp=0 with error handler if not found
  if use_qtemp=1 then
    set command = 'SELECT 1 FROM QTEMP.' || target_table || ' LIMIT 1';
    prepare qtemp_stmt from command;           
    open qtemp_cursor using target_table;
    
    -- only close if cursor successfully opened
    if use_qtemp=1 then                
      close qtemp_cursor;
    end if;                                 
  end if;
  
  -- Is QTEMP above target_schema in LIBL ?
  if use_qtemp=1 then
    set use_qtemp = coalesce(
      nullif(
        (select ORDINAL_POSITION
         from QSYS2.LIBRARY_LIST_INFO
         where TYPE='USER'
           and SYSTEM_SCHEMA_NAME in (target_schema,'QTEMP')
         order by ORDINAL_POSITION ASC
         limit 1
         ), target_schema_ordinal
      ),
      0 -- QTEMP is below
    );

    -- QTEMP was above target_schema
    if use_qtemp > 0 then                            
      set use_qtemp=1;                               
    end if;
  end if;
                                                           
  with
  syscols as (
    select 
      COLUMN_NAME,
      DATA_TYPE,
      LENGTH,
      NUMERIC_SCALE
    from QSYS2.SYSCOLUMNS
    where SYSTEM_TABLE_SCHEMA=target_schema
      and SYSTEM_TABLE_NAME=target_table
  ),
  fields as (
    select 
      COLUMN_NAME || ' '  ||
      DATA_TYPE   || ' (' || 
      LENGTH      || (
        case DATA_TYPE
          when 'DECIMAL' then ',' || NUMERIC_SCALE
          else ''
        end
      ) || ') ' || 'PATH ''lax $.' || COLUMN_NAME || ''''
      as field
    from syscols
  )
  select 
    -- insert into QTEMP using table description found in target_schema
    'INSERT INTO ' || (
      case
        when use_qtemp = 1 then 'QTEMP'
        else trim(target_schema)
      end 
    ) || '.' || trim(target_table) || 
    '(' || 
      (select listagg(all COLUMN_NAME, ', ') from syscols) || 
    ') ' || 'SELECT * FROM JSON_TABLE(?, ' || 
    '''$.' || trim(target_table) || '[*]'' ' || 
    'COLUMNS (' || listagg(all field, ', ') || 
    ') ERROR ON ERROR' || ')'
  into sql_str
  from fields;

  if use_qtemp = 0 and in_schema = 'QTEMP' then
    set sql_str = '';
  else
    set sql_str = coalesce(sql_str, '');   
  end if;
 
end; 