component displayName="NeuralNetwork" hint="A Neural Network implemented in CF" {

    public any function init() {
        this.w1 = application.mathUtils.nextGaussian();
        this.w2 = application.mathUtils.nextGaussian();
        this.w3 = application.mathUtils.nextGaussian();
        this.w4 = application.mathUtils.nextGaussian();
        this.w5 = application.mathUtils.nextGaussian();
        this.w6 = application.mathUtils.nextGaussian();
        this.b1 = application.mathUtils.nextGaussian();
        this.b2 = application.mathUtils.nextGaussian();
        this.b3 = application.mathUtils.nextGaussian();
        return this;
    }

    private void function initNeurons(){
        local.weights = [application.mathUtils.nextGaussian(), application.mathUtils.nextGaussian()];
        local.bias = application.mathUtils.nextGaussian();
        this.neuronH1 = createObject('component', 'Neuron').init(local.weights, local.bias);
        this.neuronH2 = createObject('component', 'Neuron').init(local.weights, local.bias);
        this.neuronO1 = createObject('component', 'Neuron').init(local.weights, local.bias);
    }

    public numeric function feedForward(required array x){
        if(arrayLen(x) > 2 || arrayLen(x) == 0){
            throw("Invalid array size.");
        }
        local.h1 = application.mathUtils.sigmoid(
          this.w1 * arguments.x[1] + this.w2 * arguments.x[2] + this.b1);

        local.h2 = application.mathUtils.sigmoid(
          this.w3 * arguments.x[1] + this.w4 * arguments.x[2] + this.b2);

        return application.mathUtils.sigmoid(
          this.w5 * local.h1 + this.w6 * local.h2 + this.b3);
    }

    public void function train(required array data, required array yTrues){
        // TODO: Make a better / more performant method
        // I just straight copied this from the python implementation
        var learnRate = 0.1;
        var epochs = 1000;
        for(var epoch = 1; epoch <= epochs; epoch++){
            for(var i = 1; i <= arrayLen(arguments.data); i++){
                var x = arguments.data[i];
                var yTrue = yTrues[i];

                var sumH1 = this.w1 * x[1] + this.w2 * x[2] + this.b1;
                var h1 = application.mathUtils.sigmoid(sumH1);

                var sumH2 = this.w3 * x[1] + this.w4 * x[2] + this.b2;
                var h2 = application.mathUtils.sigmoid(sumH2);

                var sumO1 = this.w5 * h1 + this.w6 * h2 + this.b3;
                var o1 = application.mathUtils.sigmoid(sumO1);
                var yPred = o1;

            // partial derivatives
                var d_L_d_yPred = -2 * (yTrue - yPred);

                // Neuron o1
                var d_ypred_d_w5 = h1 * application.mathUtils.deriveSigmoid(sumO1);
                var d_ypred_d_w6 = h2 * application.mathUtils.deriveSigmoid(sumO1);
                var d_ypred_d_b3 = application.mathUtils.deriveSigmoid(sumO1);

                var d_ypred_d_h1 = this.w5 * application.mathUtils.deriveSigmoid(sumO1);
                var d_ypred_d_h2 = this.w6 * application.mathUtils.deriveSigmoid(sumO1);

                // Neuron h1
                var d_h1_d_w1 = x[1] * application.mathUtils.deriveSigmoid(sumH1);
                var d_h1_d_w2 = x[2] * application.mathUtils.deriveSigmoid(sumH1);
                var d_h1_d_b1 = application.mathUtils.deriveSigmoid(sumH1);

                // Neuron h2
                var d_h2_d_w3 = x[1] * application.mathUtils.deriveSigmoid(sumH2);
                var d_h2_d_w4 = x[2] * application.mathUtils.deriveSigmoid(sumH2);
                var d_h2_d_b2 = application.mathUtils.deriveSigmoid(sumH2);

            // --- Update weights and biases
                // Neuron h1
                this.w1 -= learnRate * d_L_d_ypred * d_ypred_d_h1 * d_h1_d_w1;
                this.w2 -= learnRate * d_L_d_ypred * d_ypred_d_h1 * d_h1_d_w2;
                this.b1 -= learnRate * d_L_d_ypred * d_ypred_d_h1 * d_h1_d_b1;

                // Neuron h2
                this.w3 -= learnRate * d_L_d_ypred * d_ypred_d_h2 * d_h2_d_w3;
                this.w4 -= learnRate * d_L_d_ypred * d_ypred_d_h2 * d_h2_d_w4;
                this.b2 -= learnRate * d_L_d_ypred * d_ypred_d_h2 * d_h2_d_b2;

                // Neuron o1
                this.w5 -= learnRate * d_L_d_ypred * d_ypred_d_w5;
                this.w6 -= learnRate * d_L_d_ypred * d_ypred_d_w6;
                this.b3 -= learnRate * d_L_d_ypred * d_ypred_d_b3;
                
            // --- Calculate total loss at the end of each epoch
                if(epoch % 10 == 0){
                    var yPreds = arrayNew(1);
                    for(var i = 1; i <= arrayLen(data); i++){
                        arrayAppend(yPreds, this.feedForward(data[i]));
                    }
                    var loss = application.mathUtils.mseLoss(yTrues, yPreds);
                    WriteOutput("Epoch #epoch# loss: #loss#<br>");
                }
            }
        }
    }
}
