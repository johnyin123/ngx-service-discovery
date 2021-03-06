local lrucache = require "resty.lrucache"

local _host_counter_cache = ngx.shared["HOST_ACCESS_COUNT"]
local _health_check_cache = ngx.shared["HEALTH_CHECK_STATUS"]

local function _get_host_counter_cache_key()
    return ngx.var.host.."@"..ngx.worker.pid()
end
local function _get_health_check_cache_key(address)
    return address.."@"..ngx.worker.pid()
end

local _CONFIG = setmetatable({
        HOST_COUNTER=function() return 
            _host_counter_cache:incr(_get_host_counter_cache_key(),
                1, 0) or 10086 end,
        INCR_HEALTH_STATUS=function(address) return
            _health_check_cache:incr(
                _get_health_check_cache_key(address), 1, 0) end,
        CLEAR_HEALTH_STATUS=function(address) return
            _health_check_cache:delete(
                _get_health_check_cache_key(address)) end,
        IS_UPSTREAM_OK=function(address) return
            (_health_check_cache:get(_get_health_check_cache_key(
                address)) or -1) <= 3 end,
    },
    {
        __index={ 
            -- Redis configuration
            REDIS_HOST="127.0.0.1",
            REDIS_PORT=6379,
            REDIS_PASSWORD="e839fcfe725611e5:123456_78a1A",
            REDIS_DB=6,
            REDIS_TIMEOUT=1000, --unit: ms
            REDIS_MAX_IDLE_TIME=10000, --unit: ms
            REDIS_POOL_SIZE=2;

            DATA_CENTER="DATA_CENTER-dc1", -- DATA_CENTER-<datacenter name>
            NODE_TYPE="NODE_TYPE-default"; -- NODE_TYPE-<node type>

            -- NGINX Worker configuration
            DC_CACHE=lrucache.new(1),
            DC_CACHE_KEY="__DC_CACHE_KEY__",
            UPSTREAM_CACHE=lrucache.new(1),
            UPSTREAM_CACHE_KEY="__UPSTREAM_CACHE_KEY__",
            POLL_INTERVAL=0.2;
            BALANCE_ALG="RR",
            REGISTER_CENTER="RedisRegisterCenter",

            -- Health check configuration
            DEFAULT_CHECK_TIMEOUT=1000, --unit: ms
            DEFAULT_CHECK_PATH="/checkstatus",
            HEALTH_CHECK_THREAD_COUNT=10,
            HEALTH_CHECK_POLL_INTERVAL=0.2,
        },
        __metatable="permission denied",
        __newindex=function() end,
    }
)

return _CONFIG

