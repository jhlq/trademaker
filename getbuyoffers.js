var Remote = require('ripple-lib').Remote;

var CURRENCY = process.argv[2];
var ISSUER   = process.argv[3];
//'r9Dr5xwkeLegBeXq6ujinjSBLQzQ1zQGjH';

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
			'currency':'XRP'
		},
		pays: {
			'currency':CURRENCY,
			'issuer': ISSUER
		},
		limit: 1 //doesn't work; only first entry needed to get spread
	});
	/*function handlemessage(msg){
		console.log("\n\n\nHandling message:\n\n\n");
		console.log(msg);
		console.log(msg.type);
	};
	request.on('success', handlemessage);//function(res) { 
		console.log("\n\n\nHandling success:\n\n\n"); 		
		console.log(res);	//doesn't work, currency amounts become [object]
	});*/
	console.log("Sending request.");
	request.request();

	setTimeout(function() {
		remote.disconnect();
	}, (45 * 1000)); //allow 45 seconds for the transaction to complete
});


