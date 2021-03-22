# Automating Litmus Chaos

[Litmus](https://litmuschaos.io/)  is great chaos engineering tools, to test general chaos scenario, and create your custom chaos scenario. But there are many steps that you need to perform:
1. Install the Operator.
2. Install the ChaosExperiments
3. Configure the Service Account, to have proper access.
4. Label the application to reduce blast radius.
5. Then writing chaos engine. 
6. And then monior the chaosresult.

Dependency: 
1. yq.

Pheww.... to many things to do. With this repo, you will be able to perform these things with only filling [init.yaml](./init.yaml). and executing runner.sh.
## Currently Implemented
1. Node Restart experiment(without result monitoring).
## Things to do.
1. Result monitoring and displaying results at end of chaos.
2. Adding another general experiments (pod)
3. Adding support for custom experiment inside pipeline
