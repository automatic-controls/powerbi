CREATE TABLE cradlepoint.routers (
  "config_status" TEXT,
  "created_at" TIMESTAMPTZ,
  "description" TEXT,
  "device_type" TEXT,
  "full_product_name" TEXT,
  "id" INTEGER,
  "ipv4_address" TEXT,
  "locality" TEXT,
  "mac" TEXT,
  "name" TEXT,
  "reboot_required" BOOLEAN,
  "serial_number" TEXT,
  "state" TEXT,
  "state_updated_at" TIMESTAMPTZ,
  "updated_at" TIMESTAMPTZ,
  "upgrade_pending" BOOLEAN
);
CREATE INDEX cradlepoint_routers_id ON cradlepoint.routers ("id" ASC);
CREATE TABLE cradlepoint.net_devices (
  "apn" TEXT,
  "bsid" TEXT,
  "carrier" TEXT,
  "carrier_id" TEXT,
  "channel" INTEGER,
  "connection_state" TEXT,
  "dns0" TEXT,
  "dns1" TEXT,
  "esn" TEXT,
  "gateway" TEXT,
  "gsn" TEXT,
  "homecarrid" TEXT,
  "hostname" TEXT,
  "iccid" TEXT,
  "id" INTEGER,
  "imei" TEXT,
  "imsi" TEXT,
  "ipv4_address" TEXT,
  "ipv6_address" TEXT,
  "is_asset" BOOLEAN,
  "is_gps_supported" BOOLEAN,
  "is_upgrade_supported" BOOLEAN,
  "ltebandwidth" TEXT,
  "mac" TEXT,
  "manufacturer" TEXT,
  "mdn" TEXT,
  "meid" TEXT,
  "mfg_model" TEXT,
  "mfg_product" TEXT,
  "mn_ha_spi" TEXT,
  "mn_ha_ss" TEXT,
  "mode" TEXT,
  "model" TEXT,
  "modem_fw" TEXT,
  "mtu" INTEGER,
  "nai" TEXT,
  "name" TEXT,
  "netmask" TEXT,
  "pin_status" TEXT,
  "port" TEXT,
  "prlv" TEXT,
  "profile" TEXT,
  "rfband" TEXT,
  "rfband5g" TEXT,
  "rfchannel" TEXT,
  "roam" TEXT,
  "router" TEXT,
  "rxchannel" TEXT,
  "serial" TEXT,
  "service_type" TEXT,
  "ssid" TEXT,
  "summary" TEXT,
  "txchannel" TEXT,
  "type" TEXT,
  "uid" TEXT,
  "updated_at" TIMESTAMPTZ,
  "uptime" DOUBLE PRECISION,
  "ver_pkg" TEXT,
  "version" TEXT,
  "wimax_realm" TEXT,
  "router_id" INTEGER
);
CREATE INDEX cradlepoint_net_devices_id ON cradlepoint.net_devices ("id" ASC);
CREATE INDEX cradlepoint_net_devices_router_id ON cradlepoint.net_devices ("router_id" ASC);
CREATE TABLE cradlepoint.net_device_usage_samples (
  "bytes_in" BIGINT,
  "bytes_out" BIGINT,
  "created_at" TIMESTAMPTZ,
  "net_device" TEXT,
  "period" DOUBLE PRECISION,
  "uptime" DOUBLE PRECISION,
  "net_device_id" INTEGER
);
CREATE INDEX cradlepoint_net_device_usage_samples_created_at ON cradlepoint.net_device_usage_samples ("created_at" DESC);
CREATE INDEX cradlepoint_net_device_usage_samples_id ON cradlepoint.net_device_usage_samples ("net_device_id" ASC);
CREATE TABLE cradlepoint.net_device_signal_samples (
  "cinr" DOUBLE PRECISION,
  "created_at" TIMESTAMPTZ,
  "dbm" INTEGER,
  "ecio" INTEGER,
  "net_device" TEXT,
  "rsrp" DOUBLE PRECISION,
  "rsrp5g" DOUBLE PRECISION,
  "rsrp5g_highband" DOUBLE PRECISION,
  "rsrq" DOUBLE PRECISION,
  "rsrq5g" DOUBLE PRECISION,
  "rsrq5g_highband" DOUBLE PRECISION,
  "rssi" INTEGER,
  "rssnr" INTEGER,
  "signal_percent" INTEGER,
  "sinr" DOUBLE PRECISION,
  "sinr5g" DOUBLE PRECISION,
  "sinr5g_highband" DOUBLE PRECISION,
  "uptime" DOUBLE PRECISION,
  "net_device_id" INTEGER
);
CREATE INDEX cradlepoint_net_device_signal_samples_created_at ON cradlepoint.net_device_signal_samples ("created_at" DESC);
CREATE INDEX cradlepoint_net_device_signal_samples_id ON cradlepoint.net_device_signal_samples ("net_device_id" ASC);

/*
CREATE TABLE cradlepoint.net_device_health (
  "cellular_health_category" TEXT,
  "cellular_health_score" INTEGER,
  "id" INTEGER,
  "net_device" TEXT,
  "date" DATE DEFAULT CURRENT_DATE
);
CREATE INDEX cradlepoint_net_device_health_id ON cradlepoint.net_device_health ("id" ASC);
CREATE INDEX cradlepoint_net_device_health_date ON cradlepoint.net_device_health ("date" DESC);
*/