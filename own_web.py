import SocketServer
from BaseHTTPServer import BaseHTTPRequestHandler
import os

last_com = os.system("git log --name-status HEAD^..HEAD")

class Handler(BaseHTTPRequestHandler):
    ''' Main class to present webpages and authentication. '''
    def do_HEAD(self):
        print "send header"
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

    def do_AUTHHEAD(self):
        print "send header"
        self.send_response(401)
        self.send_header('WWW-Authenticate', 'Basic realm=\"Test\"')
        self.send_header('Content-type', 'text/html')
        self.end_headers()

    def do_GET(self):
        ''' Present frontpage with user authentication. '''
        if self.headers.getheader('Authorization') == None:
            self.do_AUTHHEAD()
            self.wfile.write('no auth header received')
            pass
        elif self.headers.getheader('Authorization') == 'Basic dGVzdDp0ZXN0':
            self.do_HEAD()
            self.wfile.write('Authenticated!')
            self.wfile.write(last_com)

            pass
        else:
            self.do_AUTHHEAD()
            self.wfile.write(self.headers.getheader('Authorization'))
            self.wfile.write('not authenticated')
            pass

httpd = SocketServer.TCPServer(("", 8080), Handler)

httpd.serve_forever()

if __name__ == '__main__':
    main()