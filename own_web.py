import SocketServer
from BaseHTTPServer import BaseHTTPRequestHandler
from os import popen
import os
from subprocess import PIPE
import subprocess
import shlex

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
        '''Get info about last commit, cpu and memory usage'''
        git_com = 'git log --name-status HEAD^..HEAD'
        kwargs = {}
        kwargs['stdout'] = subprocess.PIPE
        proc = subprocess.Popen(shlex.split(git_com), **kwargs)
        stdout_str = proc.communicate()

        pid = os.popen("ps aux | grep 'python own_web.py'| grep -v 'grep' | awk '{print $2}'").readlines()
        pid = [x.strip() for x in pid]
        pid = str(pid)
        pid = pid.translate(None, '[]')
        resources = os.popen('ps -p' + pid + ' -o %cpu,%mem').readlines()
        resources = [x.strip() for x in resources]

        ''' Present frontpage with user authentication. '''
        if self.headers.getheader('Authorization') == None:
            self.do_AUTHHEAD()
            self.wfile.write('no auth header received')
            pass
        elif self.headers.getheader('Authorization') == 'Basic dGVzdDp0ZXN0':
            self.do_HEAD()
            self.wfile.write('Authenticated!')
            self.wfile.write("<p>Information about last commit: {0} <p>".format(stdout_str))
            self.wfile.write("<p>Information about using resources: {0} <p>".format(resources))
            pass
        else:
            self.do_AUTHHEAD()
            self.wfile.write(self.headers.getheader('Authorization'))
            self.wfile.write('not authenticated')
            pass

httpd = SocketServer.TCPServer(("", 8083), Handler)

httpd.serve_forever()

if __name__ == '__main__':
    main()

while httpd:
git_chk = os.system('git pull')
kargs = {}
kargs['stdout'] = subprocess.PIPE
proc = subprocess.Popen(shlex.split(git_chk), **kargs)
out_git_chk = proc.communicate()

if out_git_chk:
    if out_git_chk != 'Already up to date.':
        restart_program()