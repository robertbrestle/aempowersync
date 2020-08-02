const vscode = require('vscode');
const http = require('http');

var syncing = false;
var psoutput;

/**
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {

	// reference script from extensions folder
	var aemsyncscriptpath = context.extensionPath + '\\aemsync.ps1';

	var aemserver = vscode.workspace.getConfiguration('aempowersync').get('uri');
	var aemcreds = vscode.workspace.getConfiguration('aempowersync').get('credentials');

	psoutput = vscode.window.createOutputChannel('AEM PowerSync');
	psoutput.appendLine('AEM PowerSync is now active!')

	// register commands
	context.subscriptions.push(vscode.commands.registerCommand('aempowersync.syncFromAEM', (uri) => {
		isAEMRunning(function(isUp) {
			if(isUp) {
				callAEMSync(aemsyncscriptpath, 'get', uri, aemserver, aemcreds);
			}else {
				vscode.window.showErrorMessage('Local AEM instance not running. Please start AEM and try again.');
			}
		});
	}));
	context.subscriptions.push(vscode.commands.registerCommand('aempowersync.syncToAEM', (uri) => {
		isAEMRunning(function(isUp) {
			if(isUp) {
				callAEMSync(aemsyncscriptpath, 'put', uri, aemserver, aemcreds);
			}else {
				vscode.window.showErrorMessage('Local AEM instance not running. Please start AEM and try again.');
			}
		});
	}));
}
exports.activate = activate;
function deactivate() {}

function callAEMSync(scriptpath, action, uri, aemserver, aemcreds) {
	if(syncing) {
		vscode.window.showInformationMessage('Please wait for the current sync to complete before starting a new one.');
		return;
	}
	if(typeof uri === 'undefined') {
		vscode.window.showErrorMessage('Please use the context menu options from the Explorer view.');
		return;
	}
	// need jcr_root in path
	if(uri.toString().indexOf('jcr_root') == -1) {
		vscode.window.showErrorMessage('Invalid sync path. Please ensure the jcr_root folder is open.');
		return;
	}
	// skip syncing jcr_root and /apps
	if(uri.toString().match('apps[\\|/]?$') || uri.toString().match('jcr_root[\\|/]?$')) {
		vscode.window.showErrorMessage('Invalid sync path - ' + uri);
		return;
	}

	var niceUri = uri.toString().replace(/^.*jcr_root/,'');
	vscode.window.showInformationMessage('aemsync started: ' + action + ' - ' + niceUri);
	syncing = true;

	// run ps script
	var spawn = require('child_process').spawn,child;
	child = spawn('pwsh.exe', [
		scriptpath,
		action,
		uri,
		aemserver,
		aemcreds
	]);
	child.stdout.on('data',function(data){
		psoutput.appendLine('' + data);
	});
	child.stderr.on('data',function(data){
		psoutput.appendLine('Error: ' + data);
	});
	child.on('exit',function(){
		psoutput.appendLine('aemsync completed');
		vscode.window.showInformationMessage('aemsync completed: ' + action + ' - ' + niceUri);
		syncing = false;
	});
	child.stdin.end();
}

function isAEMRunning(callback) {
	var aemserver = vscode.workspace.getConfiguration('aempowersync').get('uri');
	var aemhost = aemserver.replace(/http:\/\/(.*?):.*/,'$1');
	var aemport = Number(aemserver.replace(/http:\/\/.*:(.*)/,'$1'));
	var options = {
		host: aemhost,
		port: aemport,
		method: 'HEAD',
		path: vscode.workspace.getConfiguration('aempowersync').get('healthcheck'),
		timeout: 5000
	};
	var aemreq = http.request(options, (res) => {
		// for consistency with handling a null healthcheck, moved logic to event.close
	}).on('close', () => {
		if(aemreq.res != null && aemreq.res.statusCode != null) {
			psoutput.appendLine('Healthcheck: ' + aemreq.res.statusCode);
			callback(true);
		}else {
			psoutput.appendLine('Healthcheck: null');
			callback(false);
		}
	}).end();
}

module.exports = {
	activate,
	deactivate
}