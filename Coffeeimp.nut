/**
 * Made for Jura IMPRESSA J9.3 machine
 */
class Coffeeimp {

    _in = [];
    _out = "";
    _uart = null;
    _outputTimer = null;
    _resolve = null;
    _reject = null;

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
            // clear input buffer
            this._in = [];

            // save resolve/reject callbacks
            this._resolve = resolve;
            this._reject = reject;

            // send message
            local message = this._encode(command + "\r\n");
            this._uart.write(message);
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
                            local r = format("%04X-%04X: ", address, address + STEP - 1) + v.slice(3);
                            res += r;
                            if (log) server.log(r);
                        });
                    return p;
                }.bindenv(this)
            )

            .then(@(v) resolve(res));
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
        if (this._resolve) this._resolve(this._out);
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
}
