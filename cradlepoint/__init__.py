import logging.handlers
import NetDevices
import Routers
import net_device_usage
import net_device_signal
def main():
    ret = False
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    logging.basicConfig(level=logging.INFO)
    try:
        logger.info("Syncing net_devices...")
        ret|=NetDevices.get_net_devices()
        logger.info("Syncing routers...")
        ret|=Routers.get_routers()
        logger.info("Syncing net_device_usage...")
        ret|=net_device_usage.get_net_device_usage()
        logger.info("Syncing net_device_signal...")
        ret|=net_device_signal.get_net_device_signal()
    except Exception as e:
        logger.exception(e)
        ret = True
    exit(1 if ret else 0)

if __name__ == '__main__':
    main()