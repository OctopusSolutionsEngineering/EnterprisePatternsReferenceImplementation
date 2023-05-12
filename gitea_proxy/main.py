from bottle import route, run, request

@route('/', method='POST')
def index(name):
    body = request.body.readlines()
    requests.get(api_url)

run(host='localhost', port=4000)