<html>
	<body>
		<h2>ColdFusion Neural Network</h2>
		<hr>
		<cfscript>
			application.mathUtils = createObject('component', 'MathUtils').init();
			local.network = createObject('component', 'NeuralNetwork').init();
			//writeOutput(local.network.feedForward([2,3]));
			
			// Testing
			
			// local.neuron = createObject('component', 'Neuron').init([0,1],4);
			// writeOutput(local.neuron.feedForward([2,3]));

			//writeOutput(application.mathUtils.mseLoss([1,0,0,1],[0,0,0,0]));
			local.data = [[-2,-1], [25,6], [17,4], [-15,-6]];
			local.trues = [1, 0, 0, 1];
			local.network.train(local.data, local.trues);
		</cfscript>
	</body>
</html>