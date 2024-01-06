component displayName="Neuron" hint="A Neuron for usage in a neural network" {
    
    public any function init(required array weights, required numeric bias) {
        this.weights = arguments.weights;
        this.bias = arguments.bias;
        return this;
    }

    public numeric function feedForward(required array inputs){
        return application.mathUtils.sigmoid(
          application.mathUtils.dotProduct(this.weights, arguments.inputs) + this.bias
        );
    }
}