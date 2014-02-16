request = require 'request'

module.exports = (esUrl) ->
	(options, callback) ->
		app = options.app
		worker = options.worker

		esQuery =
			"query":
				"bool":
					"must": [
						{
							"range":
								"logs.gummi_output":
									"from": "1"
									"to": "2"
						}
					]
					"must_not": []
					"should": []
			"from": 0
			"size": 50

		esQuery['query']['bool']['must'].push {term: {"logs.gummi_app.raw": app}}
		if worker
			esQuery['query']['bool']['must'].push {term: {"logs.gummi_worker.raw": worker}}

		options =
			url: "#{esUrl}/_search"
			method: 'POST'
			body: JSON.stringify esQuery

		request options, (err, esRes, body) ->
			return callback err if err

			data = JSON.parse body
			return callback data.error if data.error

			response = data['hits']['hits'].map (doc) ->
				doc['_source']['@timestamp'] + ': ' + doc['_source']['message']

			callback null, response
