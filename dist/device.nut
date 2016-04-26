// libs
/**
 * Promises for Electric Imp/Squirrel
 *
 * @author Mikhail Yurasov <mikhail@electricimp.com>
 * @author Aron Steg <aron@electricimp.com>
 *
 * @version 2.0.0
 */
class Promise {
    static version = [2, 0, 0];

    static STATE_PENDING = 0;
    static STATE_RESOLVED = 1;
    static STATE_REJECTED = 2;
    static STATE_CANCELLED = 3;

    _state = null;
    _value = null;

    /* @var {{resole, reject}[]} _handlers */
    _handlers = null;

    /**
    * @param {function(resolve, reject)} action - action function
    */
    constructor(action) {
        this._state = this.STATE_PENDING;
        this._handlers = [];

        try {
            action(
                this._resolve.bindenv(this)
                this._reject.bindenv(this)
            );
        } catch (e) {
            this._reject(e);
        }
    }

    /**
     * Execute chain of handlers
     */
    function _callHandlers() {
        if (this.STATE_PENDING != this._state) {
            foreach (handler in this._handlers) {
                (/* create closure and bind handler to it */ function (handler) {
                    if (this._state == this.STATE_RESOLVED) {
                        if ("resolve" in handler && "function" == type(handler.resolve)) {
                            imp.wakeup(0, function() {
                                handler.resolve(this._value);
                            }.bindenv(this));
                        }
                    } else if (this._state == this.STATE_REJECTED) {
                        if ("reject" in handler && "function" == type(handler.reject)) {
                            imp.wakeup(0, function() {
                                handler.reject(this._value);
                            }.bindenv(this));
                        }
                    } else if (this._state == this.STATE_CANCELLED) {
                        if ("cancel" in handler && "function" == type(handler.cancel)) {
                            imp.wakeup(0, function() {
                                handler.cancel(this._value);
                            }.bindenv(this));
                        }
                    }
                })(handler);
            }

            this._handlers = [];
        }
    }

    /**
     * Resolve promise with a value
     */
    function _resolve(value = null) {
        if (this.STATE_PENDING == this._state) {
            // if promise is resolved with another promise
            // let it resolve/reject this one,
            // otherwise resolve immideately
            if (this._isPromise(value)) {
                value.then(
                    this._resolve.bindenv(this),
                    this._reject.bindenv(this)
                );
            } else {
                this._state = this.STATE_RESOLVED;
                this._value = value;
                this._callHandlers();
            }
        }
    }

    /**
     * Reject promise for a reason
     */
    function _reject(reason = null) {
        if (this.STATE_PENDING == this._state) {
            this._state = this.STATE_REJECTED;
            this._value = reason;
            this._callHandlers();
        }
    }

   /**
    * Check if a value is a Promise.
    * @param {Promise|*} value
    * @return {boolean}
    */
    function _isPromise(value) {
        if (
            // detect that the value is some form of Promise
            // by the fact it has .then() method
            (typeof value == "instance")
            && ("then" in value)
            && (typeof value.then == "function")
          ) {
            return true
        }

        return false
    }

   /**
    * Add handlers on resolve/rejection
    * @param {function} onResolve
    * @param {function|null} onReject
    * @return {this}
    */
    function then(onResolve, onReject = null) {
        this._handlers.push({
            "resolve": onResolve
        });

        if (onReject) {
            this._handlers.push({
                "reject": onReject
            });
        }

        this._callHandlers();
        return this;
    }

   /**
    * Add handler on rejection
    * @param {function} onReject
    * @return {this}
    */
    function fail(onReject) {
        this._handlers.push({
            "reject": onReject
        });

        this._callHandlers();
        return this;
    }

   /**
    * Add handler that is executed both on resolve and rejection
    * @param {function(value)} handler
    * @return {this}
    */
    function finally(handler) {
        this._handlers.push({
            "resolve": handler,
            "reject": handler
        });

        this._callHandlers();
        return this;
    }

   /**
    * Add handlers on cancellation
    * @param {function()} onCancel
    * @return {this}
    */
    function cancelled(onCancel) {
      this._handlers.push({
        "cancel": onCancel
      });

      this._callHandlers();
      return this;
    }

   /**
    * Add handler that is executed on resolve/reject/cancel
    * @param {function(value)} handler
    * @return {this}
    */
    function always(handler) {
        this._handlers.push({
            "resolve": handler,
            "reject": handler,
            "cancel": handler
        });

        this._callHandlers();
        return this;
    }

    /**
     * Cancel a promise
     * - No .then/.fail/.finally handlers will be called
     * - .cancelled handler will be called
     * @param {*} reason - value that will be passed to .cancelled handler
     */
    function cancel(reason = null) {
        if (this.STATE_PENDING == this._state) {
            this._state = this.STATE_CANCELLED;
            this._value = reason;
            this._callHandlers();
        }
    }

    /**
     * While loop with Promise's
     * Stops on continueCallback() == false or first rejection of looped Promise
     *
     * @param {function:boolean} condition - if returns false, loop stops
     * @param {function:Promise} next - function to get next promise in the loop
     * @return {Promise} Promise that is resolved/rejected with the last value that come from looped promise when loop finishes
     */
    static function loop(condition, next) {
        return (this)(function (resolve, reject) {

            local doLoop;
            local lastResolvedWith;

            doLoop = function() {
                if (condition()) {
                    next().then(
                        function (v) {
                            lastResolvedWith = v;
                            imp.wakeup(0, doLoop)
                        },
                        reject
                    );
                } else {
                    resolve(lastResolvedWith);
                }
            }

            imp.wakeup(0, doLoop);

        }.bindenv(this));
    }

    /**
     * Returns Promise that resolves when
     * all promises in chain resolve:
     * one after each other
     *
     * @param {{Promise|function}[]} promises - array of Promises/functions that return Promises
     * @return {Promise} Promise that is resolved/rejected with the last value that come from looped promise
     */
    static function serial(promises) {
        local i = 0;
        return this.loop(
            @() i < promises.len(),
            function () {
                return "function" == type(promises[i])
                    ? promises[i++]()
                    : promises[i++];
            }
        )
    }

    /**
     * Execute Promises in parallel.
     *
     * @param {{Primise|functiuon}[]} promises
     * @param {wait} wait - wait for all promises to finish?
     * @returns {Promise}
     */
    static function _parallel(promises, wait) {
        return (this)(function (resolve, reject) {
            local resolved = 0;

            local checkDone = function(v = null) {
                if ((!wait && resolved == 1) || (wait && resolved == promises.len())) {
                    resolve(v);
                    return true;
                }
            }

            if (!checkDone()) {
                for (local i = 0; i < promises.len(); i++) {
                    (
                        "function" == type(promises[i])
                            ? promises[i]()
                            : promises[i]
                    )
                    .then(function (v) {
                        resolved++;
                        checkDone(v);
                    }, reject);
                }
            }

        }.bindenv(this));
    }

    /**
     * Execute Promises in parallel and resolve when they are all done.
     * Returns Promise that resolves with last paralleled Promise value
     * or rejects with first rejected paralleled Promise value.
     *
     * @param {{Primise|functiuon}[]} promises
     * @returns {Promise}
     */
    static function parallel(promises) {
        return this._parallel(promises, true);
    }

    /**
     * Execute Promises in parallel and resolve when the first is done.
     * Returns Promise that resolves/rejects with the first
     * resolved/rejected Promise value.
     *
     * @param {{Primise|functiuon}[]} promises
     * @returns {Promise}
     */
    static function first(promises) {
        return this._parallel(promises, false);
    }
}

// Coffeeimp class
/**
 * Made for Jura IMPRESSA J9.3 machine
 */
class Coffeeimp {

    _in = [];
    _out = "";
    _uart = null;
    _outputTimer = null;
    _resolve = null;

    static OUTPUT_THROTTLE = 0.25;

    constructor(uart) {
        this._uart = uart;
        this._uart.configure(9600, 8, PARITY_NONE, 1, NO_CTSRTS, this._onUart.bindenv(this));
    }

    /**
     * Send a command to the machine
     * Line endings are added automatocally
     * @param {string} command
     * @return {Promise}
     */
    function sendCommand(command) {
        return Promise(function (resolve, reject) {
            if (this._resolve) {
                reject("Busy")
            } else {
                // clear input buffer
                this._in = [];

                // save resolve callback
                this._resolve = resolve;

                // send message
                local message = this._encode(command + "\r\n");
                this._uart.write(message);
            }
        }.bindenv(this));
    }

    /**
     * Dump eeprom to console
     * @param {number=0} start
     * @param {number=0x400} end
     * @param {bool} log
     * @return {Promise}
     */
    function dumpEEPROM(start = 0, end = 0x0400, log = true) {
        local STEP = 0x10;
        local res = "";

        // align start address
        start = start - start % STEP;
        local address = start - STEP;

        return Promise(function (resolve, reject) {

            // issue RT: commands
            Promise.loop(
                function () {
                    return address < end - STEP;
                },
                function () {
                    address += STEP;
                    local p = this.sendCommand("RT:" + format("%04X", address))
                        .then(function (v) {
                            local r =
                                format("%04X-%04X: ", address, address + STEP - 1)
                                + v.slice(3, 67);
                            res += r + "\n";
                            if (log) server.log(r);
                        });
                    return p;
                }.bindenv(this)
            )
            .then(@(v) resolve(res), reject);

        }.bindenv(this));
    }

    /**
     * Get # of espressos made
     * @return {Promise}
     */
    function getEspressosCount() {
        return this._readEEPROM(0x0000);
    }

    /**
     * Get # of ristrettos made
     * @return {Promise}
     */
    function getRistrettosCount() {
        return this._readEEPROM(0x0001);
    }

    /**
     * Get # of 2-espressi made
     * @return {Promise}
     */
    function getCoffeesCount() {
        return this._readEEPROM(0x0002);
    }

    /**
     * Get # of capuccinos made
     * @return {Promise}
     */
    function getCappuccinosCount() {
        return this._readEEPROM(0x0004);
    }

    /**
     * Get # of latte macchiatos made
     * @return {Promise}
     */
    function getLatteMacchiatosCount() {
        return this._readEEPROM(0x0005);
    }

    /**
     * Get # of 1-portion milks
     * @return {Promise}
     */
    function get1PortionMilkCount() {
        return this._readEEPROM(0x0013);
    }

    /**
     * Get # of hot waters made
     * @return {Promise}
     */
    function getHotWaterCount() {
        return this._readEEPROM(0x0014);
    }

    /**
     * Get # of 2-espressi made
     * @return {Promise}
     */
    function get2EspressosCount() {
        return this._readEEPROM(0x00E0);
    }

    /**
     * Get # of 2-coffees made
     * @return {Promise}
     */
    function get2CoffeesCount() {
        return this._readEEPROM(0x00E2);
    }

    /**
     * Read a word from EEPROM as integer
     * @return {Promise}
     */
    function _readEEPROM(address) {
        return Promise(function (resolve, reject) {
            this.sendCommand(format("RE:%04X", address))
                .then(function (res) {
                    resolve(this._hexStringToInt(res.slice(3, 7)));
                }.bindenv(this), reject);
        }.bindenv(this));
    }

    /**
     * Handle arriving data:
     *  - receive
     *  - decode
     *  - detect completed messages
     */
    function _onUart() {
        local m;

        while (true) {
            // read data
            m = this._uart.read();
            if (-1 == m) break;

            this._in.append(m);

            // decode every 4 bytes
            if (4 == this._in.len()) {
                local md = this._decodeByte(this._in);
                md = format("%c", md);
                this._out += md;
                this._in = [];
            }
        }

        // detect message completion
        if (this._outputTimer) imp.cancelwakeup(this._outputTimer);
        this._outputTimer = imp.wakeup(this.OUTPUT_THROTTLE, this._onMessage.bindenv(this));
    }

    /**
     * Handle completed message arrival
     */
    function _onMessage() {
        imp.cancelwakeup(this._outputTimer);
        this._outputTimer = null;

        if (this._resolve) {
            this._resolve(this._out);
            this._resolve = null;
        }

        this._out = "";
    }

    /**
     * Encode a message
     * @param {string} message
     */
    function _encode(message) {
        local res = blob();

        for (local i = 0; i < message.len(); i++) {
            local e = this._encodeByte(message[i]);
            for (local j = 0; j < e.len(); j++) {
                res.writen(e[j], 'b');
            }
        }

        return res;
    }

    /**
     * Encode a single byte in 4-byte sequence as Jura likes it
     * @param {integer} byteValue
     */
    function _encodeByte(byteValue) {
        local d = [255, 255, 255, 255];

        // scramble data as Jura likes it
        for (local i = 0; i < d.len(); i++) {
            d[i] = this._setBit(d[i], 2, this._getBit(byteValue, i * 2));
            d[i] = this._setBit(d[i], 5, this._getBit(byteValue, i * 2 + 1));
        }

        return d;
    }

    /**
     * Decode a 4-byte sequence from machine in to a single byte
     * @param {integer[4]} quartet
     */
    function _decodeByte(quartet) {
        assert(quartet.len() == 4);

        local res = 0;

        for (local i = 0; i < 4; i++) {
            res = this._setBit(res, i * 2, this._getBit(quartet[i], 2));
            res = this._setBit(res, i * 2 + 1, this._getBit(quartet[i], 5));
        }

        return res;
    }

    /**
     * Get a bit from an integer
     */
    function _getBit(value, bit) {
        return (value >> bit) & 0x01;
    }

    /**
     * Update a bit in an integer
     */
    function _setBit(value, bit, bitValue) {
        if (bitValue) {
            return value | (1 << bit);
        } else {
            return value & ~(1 << bit);
        }
    }

    /**
     * Convert hex string to an integer
     * @see https://electricimp.com/docs/troubleshooting/tips/hex/
     */
    function _hexStringToInt(hexString) {
        // Get the integer value of the remaining string
        local intValue = 0;

        foreach (character in hexString) {
            local nibble = character - '0';
            if (nibble > 9) nibble = ((nibble & 0x1F) - 7);
            intValue = (intValue << 4) + nibble;
        }

        return intValue;
    }
}

//

function main() {
    // enable powersave mode
    imp.setpowersave(true);

    local m = Coffeeimp(hardware.uart12);
//    m.sendCommand("RT:0000").then(@(v) server.log(v), @(e) server.error(e));
//    m.dumpEEPROM(0, 16 * 2, false).then(@(v) server.log(v), @(e) server.error(e));
//    m.getEspressosCount().then(@(v) server.log(v), @(e) server.error(e));
//    m.get2EspressosCount().then(@(v) server.log(v), @(e) server.error(e));
    m.getRistrettosCount().then(@(v) server.log(v), @(e) server.error(e));
}

main();
