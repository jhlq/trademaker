function mc(startTime="2015-01-01",endTime="2015-01-02")
	rd="""{
		"base": {
		"currency": "USD",
		"issuer": "rvYAfWj5gh67oV6fW32ZzP3Aw4Eubs59B"
		},
		"counter": {
		"currency": "BTC",
		"issuer": "rvYAfWj5gh67oV6fW32ZzP3Aw4Eubs59B"
		},
		"endTime": "$(endTime)T00:00:00.000Z",
		"startTime": "$(startTime)T00:00:00.000Z",
		"timeIncrement": "minute",
		"timeMultiple": 15,
		"format": "json"
	}"""
	f=open("rd.txt","w");write(f,rd);close(f)
	`curl -X POST -d @rd.txt https://api.ripplecharts.com/api/offers_exercised --header "Content-Type:application/json"`
end
r=readall(mc("2015-01-01","2015-02-01"))
