create or replace function BOLIB/GENERATE_GROOVY ( 
  SCHEMANAME VARCHAR(50), 
  TABLENAME VARCHAR(50))
  RETURNS VARCHAR(20000)   
  LANGUAGE SQL 
  SPECIFIC BOLIB/GENGROOVY
  SET OPTION DBGVIEW = *SOURCE
   
begin 
  declare model varchar (20000);
  declare CR char(2);
  declare targetschema varchar(50);

  set CR = CHR(13) || CHR(10);
  set targetschema = (
    case
      when trim(SCHEMANAME) <> '' then trim(SCHEMANAME)
      else ( -- Find schema based on LIBL
        select 
          TABLE_SCHEMA
        from QSYS2.SYSTABLES a
          left outer join QSYS2.LIBRARY_LIST_INFO b
            on a.TABLE_SCHEMA=b.SCHEMA_NAME
        where a.TABLE_NAME=TABLENAME
        order by b.ordinal_position
        limit 1
      )
    end
  );

  with
  syscols as (
    select
      COLUMN_NAME,
      DATA_TYPE,
      COLUMN_TEXT
    from QSYS2.SYSCOLUMNS
    where TABLE_NAME=TABLENAME
      and TABLE_SCHEMA = targetschema
  ),
  fields as (
    select
      '    ' || RPAD((
        case DATA_TYPE
          when 'SMALLINT'   then 'short'
          when 'INTEGER'    then 'int'
          when 'DECIMAL'    then 'java.math.BigDecimal'
          when 'DECFLOAT'   then 'java.math.BigDecimal'
          when 'REAL'       then 'float'
          when 'DOUBLE'     then 'double'
          when 'CHAR'       then 'String'
          when 'VARCHAR'    then 'String'
          when 'BINARY'     then 'byte[]'
          when 'VARBINARY'  then 'byte[]'
          when 'GRAPHIC'    then 'String'
          when 'VARGRAPHIC' then 'String'
          when 'CLOB'       then 'java.sql.Clob'
          when 'BLOB'       then 'java.sql.Blob'
          when 'DBCLOB'     then 'java.sql.Clob'
          when 'ROWID'      then 'java.sql.RowId'
          when 'XML'        then 'java.sql.SQLXML'
          when 'DATE'       then 'java.sql.Date'
          when 'TIME'       then 'java.sql.Time'
          when 'TIMESTAMP'  then 'java.sql.Timestamp'
          else 'def'
        end), 20, ' ') || ' ' || 
        COLUMN_NAME || '  // ' || COLUMN_TEXT
      as field
    from syscols
  )
  select
    'package com.group.model' || CR || CR ||
    'class ' || 'MYTABLE' || 'Record{' || CR ||
    listagg(all field, CR) || CR || '}'
  into model
  from fields
  limit 1;

  return model;
end; 