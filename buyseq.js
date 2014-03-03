var Remote = require('ripple-lib').Remote;
var Amount = require('ripple-lib').Amount;

var CURRENCY = process.argv[4];
var ISSUER   = process.argv[5];
var MY_ADDRESS         = 'rw8iVnARvhQ3WNMUEAaamSHqBEGzTrnAEE'; // jsbot
var MY_SECRET         = 'ssJKV6dnA88ZL71m6kGYt98bzHc2W';       // jsbot secret

var TAKER_GETS   = process.argv[2]*1000000;//first commandlineargument times dropsperxrp
var TAKER_PAYS   = {currency: CURRENCY, value:  process.argv[3], issuer: ISSUER};

var remote = new Remote({
   trace:         true,
   trusted:      true,
   local_signing:   true,
   secure:         true,
   local_fee:      true,
   fee_cushion:   1.5,
   servers: [   { host: 's_west.ripple.com', port: 443, secure: true },
            { host: 's_east.ripple.com', port: 443, secure: true }   ]
});


remote.connect(function() {
	remote.set_secret(MY_ADDRESS, MY_SECRET);
	var transaction = remote.transaction();

	transaction.offer_create({
		from: MY_ADDRESS,
		taker_pays: TAKER_PAYS,   
		taker_gets: TAKER_GETS,
		cancel_sequence: process.argv[6]
	});

	transaction.submit(function(err, res) {
		console.log(JSON.stringify(err, null, 4));
		console.log(JSON.stringify(res, null, 4));
	});

	setTimeout(function() {
		remote.disconnect();
	}, (45 * 1000)); //allow 15 seconds for the transaction to complete
});
