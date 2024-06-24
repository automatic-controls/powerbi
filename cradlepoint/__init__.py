import logging.handlers
import vars
import Routers
import NetDevices
#import NetDeviceHealth
import NetDeviceUsageSamples
import NetDeviceSignalSamples
def main():
    ret = False
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s %(levelname)s > %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    vars.hits = 0
    try:
        logger.info("Syncing routers...")
        ret|=Routers.get_routers()
        logger.info("Syncing net_devices...")
        ret|=NetDevices.get_net_devices()
        #logger.info("Syncing net_device_health...")
        #ret|=NetDeviceHealth.get_net_device_health()
        logger.info("Syncing net_device_usage_samples...")
        ret|=NetDeviceUsageSamples.get_net_device_usage_samples()
        logger.info("Syncing net_device_signal_samples...")
        ret|=NetDeviceSignalSamples.get_net_device_signal_samples()
        logger.info("Finished with {} API hits.".format(vars.hits))
    except Exception as e:
        logger.exception(e)
        ret = True
    exit(1 if ret else 0)

if __name__ == '__main__':
    main()