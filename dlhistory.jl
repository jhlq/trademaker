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
r=readall(mc("2015-01-01","2015-01-02"))
function parseprice(r)
	l=search(r,"open\":")
	if isempty(collect(l))
		return Void
	end
	l=l[end]
	le=search(r[l:end],',')
	p=r[l+1:l+le-2]
	return parse(Float64,p),r[l+le:end]
end
prices=Float64[]
t=parseprice(r)
while t!=Void
	push!(prices,t[1])
	t=parseprice(t[2])
end
