component displayName="MathUtils" hint="Math utility functions" {

    public any function init() {
        this.javaRandom = createObject('java', 'java.util.Random');
        return this;
    }

    public numeric function nextGaussian(){
        return this.javaRandom.nextGaussian(); // lol yeah I cheated
    }

    // https://en.cppreference.com/w/cpp/types/numeric_limits/min
    public numeric function epsilon(){
        return 0.0000000000000000000000000000000000000117549;
    }

    public numeric function eulersNum(){
        return 2.7182818284590452353602874713527;
    }

    public numeric function dotProduct(required array a, required array b){
        local.dp = 0;
        if(arrayLen(arguments.a) != arrayLen(arguments.b)){
            throw("Vector lengths do not match.");
        }
        for(var i = 1; i <= arrayLen(arguments.a); i++){
            local.dp += (arguments.a[i] * arguments.b[i]);
        }
        return local.dp;
    }
    
    public numeric function mean(required array values){
        return this.sigma(arguments.values) / arrayLen(arguments.values);
    }

    public numeric function stdDev(required array values){
        local.avg = this.mean(arguments.values);
        local.s = 0;
        local.n = arrayLen(n);
        for(var i = 1; i <= local.n; i++){
            local.s += (arguments.values[i] - local.avg) * (arguments.values[i] - local.avg);
        }
        return sqr(local.s / (local.n - 1));
    }

    public numeric function sigma(required array values, numeric start, numeric end){
        arguments.start = !isDefined('arguments.start') ?: 1;
        arguments.end = !isDefined('arguments.end') ?: arrayLen(arguments.values);
        local.s = 0;
        if(arguments.start > arguments.end) {
            throw("Invalid start and/or end parameters.");
        }
        for(var i = arguments.start; i <= arguments.end; i++){
            local.s += arguments.values[i];
        }
        return local.s;
    }

    // Sigmoid activation function: f(x) = 1 / (1 + e^(-x))
    public numeric function sigmoid(required numeric x){
        return 1 / (1 + exp(-arguments.x));
    }

    // Derivate of sigmoid: f'(x) = f(x) * (1 - f(x))
    public numeric function deriveSigmoid(required numeric x){
        local.fx = this.sigmoid(arguments.x);
        return local.fx * (1 - local.fx);
    }

    // Mean Squared Error (MSE) Loss 
    public numeric function mseLoss(required array yTrue, required array yPred){
        if(arrayLen(arguments.yTrue) != arrayLen(arguments.yPred)){
            throw("True and predicted value lengths do not match. 
                #arrayLen(arguments.yTrue)# != #arrayLen(arguments.yPred)#"
            );
        }
        local.squaredErrors = arrayNew(1);
        for(var i = 1; i <= arrayLen(arguments.yPred); i++){
            local.squaredErrors[i] = (arguments.yTrue[i] - arguments.yPred[i]) ^ 2;
        }
        return this.mean(local.squaredErrors);
    }

}