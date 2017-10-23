# tensoflow.__init__ calls _os.path.basename(_sys.argv[0])
# so we need to create a synthetic argv.
import sys
if not hasattr(sys, 'argv'):
    sys.argv  = ['combo']

import json
import os
import numpy as np
import importlib
import runner_utils
import socket
import time
import math

node_pid = "%s,%i" % (socket.gethostname(), os.getpid())
print("node,pid: " + node_pid)

logger = None

def get_logger():
    """ Set up logging """
    global logger
    if logger is not None:
        return logger
    import logging, sys
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.DEBUG)
    h = logging.StreamHandler(stream=sys.stdout)
    fmtr = logging.Formatter('%(asctime)s %(name)s %(levelname)-9s %(message)s',
                             datefmt='%Y/%m/%d %H:%M:%S')
    h.setFormatter(fmtr)
    logger.addHandler(h)
    return logger

def run(hyper_parameter_map, obj_param):

    logger = get_logger()

    framework = hyper_parameter_map['framework']
    logger.debug("IMPORT START " + str(time.time()))
    if framework == 'keras':
        import combo_baseline_keras2
        pkg = combo_baseline_keras2
    else:
        raise ValueError("Unsupported framework: {}".format(framework))
    logger.debug("IMPORT STOP")

    runner_utils.format_params(hyper_parameter_map)


    # params is python dictionary
    params = pkg.initialize_parameters()
    for k,v in hyper_parameter_map.items():
        #if not k in params:
        #    raise Exception("Parameter '{}' not found in set of valid arguments".format(k))
        if(k=="dense"):
            v = [int(i) for i in v]
        if(k=="dense_feature_layers"):
            v = [int(i) for i in v]
        if(k=="cell_features"):
            cp_str = v
            v = list()
            v.append(cp_str)
        params[k] = v

    logger.debug("WRITE_PARAMS START")
    runner_utils.write_params(params, hyper_parameter_map)
    logger.debug("WRITE_PARAMS STOP")

    #format the hyperparameters for benchmark python
    cp_str = hyper_parameter_map['cell_features']
    hyper_parameter_map['cell_features']=list()
    hyper_parameter_map['cell_features'].append(cp_str)

    #format the hyperparameters for benchmark python  
    if (len(hyper_parameter_map['dense']) > 0):
        hyper_parameter_map['dense'] = [int(i) for i in hyper_parameter_map['dense']]
    if (len(hyper_parameter_map['dense_feature_layers']) > 0):
        hyper_parameter_map['dense_feature_layers'] = [int(i) for i in hyper_parameter_map['dense_feature_layers']]
     
    history = pkg.run(params)

    if framework == 'keras':
         # works around this error:
         # https://github.com/tensorflow/tensorflow/issues/3388
         try:
             from keras import backend as K
             K.clear_session()
         except AttributeError:      # theano does not have this function
             pass

     # use the last validation_loss as the value to minimize
    obj_loss = history.history['val_loss']
    if(obj_param == "val_loss"):
        if(math.isnan(obj_loss[-1])):
            last_val = 99999999
        else:
            last_val = obj_loss[-1]
    else:
        raise ValueError("Unsupported objective function (use obj_param to specify val_corr or val_loss): {}".format(framework))

    return last_val

if __name__ == '__main__':

    logger = get_logger()
    print("argv: ", sys.argv)

    ( _ ,
      param_string, 
      instance_directory,
      model_name,
      framework,
      exp_id,
      run_id,
      benchmark_timeout,
      obj_param
    ) = sys.argv

    print("model_name: " + model_name)
    print("R objective function: " + obj_param)

    benchmark_timeout = int(benchmark_timeout)

    logger.debug("RUN INIT START")
    hyper_parameter_map = runner_utils.init(param_string, instance_directory, framework, 'save_path')
    hyper_parameter_map['model_name'] = model_name
    hyper_parameter_map['experiment_id'] = exp_id
    hyper_parameter_map['run_id'] = run_id
    hyper_parameter_map['timeout'] = benchmark_timeout
    # clear sys.argv so that argparse doesn't object
    sys.argv = ['p1b1_runner']

    result = run(hyper_parameter_map, obj_param)
    logger.debug("WRITE OUTPUT START")
    runner_utils.write_output(result, instance_directory)
    logger.debug("WRITE OUTPUT STOP")
    logger.debug("RUN STOP")