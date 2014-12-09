var Remote = require('ripple-lib').Remote;
var Amount = require('ripple-lib').Amount;

var CURRENCY = process.argv[4];
var ISSUER   = process.argv[5];
var MY_ADDRESS         = process.argv[7];
var MY_SECRET         = process.argv[8];

var TAKER_GETS   = process.argv[2]*1000000;//first commandlineargument times dropsperxrp
var TAKER_PAYS   = '1/'+CURRENCY+'/' + ISSUER//{currency: CURRENCY, value:  process.argv[3], issuer: ISSUER};

var remote = new Remote({
   trace:         true,
   trusted:      true,
   local_signing:   true,
   secure:         true,
   local_fee:      true,
   fee_cushion:   1.5,
   servers: [{
		host:    's1.ripple.com'
		, port:    443
		, secure:  true
	}]
});


remote.connect(function() {
  remote.setSecret(MY_ADDRESS, MY_SECRET);

  var transaction = remote.createTransaction('OfferCreate', {
    account: MY_ADDRESS,
    taker_pays: TAKER_PAYS,
    taker_gets: TAKER_GETS
  });
	var dc=0;
	remote.on('success',function(msg){
		console.log('Success! ');
		remote.disconnect();
		dc=1;
	});
	remote.on('error',function(msg){
		console.log('Something went wrong. ');
		remote.disconnect();
		dc=1;
	});

	transaction.submit(function(err, res) {
		console.log(JSON.stringify(err, null, 4));
		console.log(JSON.stringify(res, null, 4));
	});
	setTimeout(function() {
		if (dc==0){
			setTimeout(function() {
				remote.disconnect();
			}, (45 * 1000));
		}
	},(5*1000));
});
