var Remote = require('ripple-lib').Remote;

var CURRENCY = process.argv[2];
var ISSUER   = process.argv[3];

var remote = new Remote({
	trace:	true,
	trusted:        true,
	local_signing:  true,
//	local_fee:      true,
//	fee_cushion:     1.5,
	servers: [{
		host:    's1.ripple.com'
		, port:    443
		, secure:  true
	}]
});
remote.connect(function() {
	var request = remote.request_book_offers({
		gets: {
			'currency':CURRENCY,
			'issuer': ISSUER
		},
		pays: {
			'currency':'XRP'
		},
		limit: 1
	});

	request.request();

	setTimeout(function() {
		remote.disconnect();
	}, (45 * 1000));
});


