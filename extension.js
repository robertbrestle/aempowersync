const vscode = require('vscode');
const http = require('http');
const { url } = require('inspector');

var syncing = false;
var psoutput;

/**
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {

	// reference script from extensions folder
	var aemsyncscriptpath = context.extensionPath + '\\aemsync.ps1';

	// config
	var powershellexe = vscode.workspace.getConfiguration('aempowersync').get('powershell');
	var aemserver = vscode.workspace.getConfiguration('aempowersync').get('uri');
	var aemcreds = vscode.workspace.getConfiguration('aempowersync').get('credentials');

	psoutput = vscode.window.createOutputChannel('AEM PowerSync');
	psoutput.appendLine('AEM PowerSync is now active!')

	// register commands
	context.subscriptions.push(vscode.commands.registerCommand('aempowersync.syncFromAEM', (uri) => {
		isAEMRunning(function(isUp) {
			if(isUp) {
				callAEMSync(powershellexe, aemsyncscriptpath, 'get', uri, aemserver, aemcreds);
			}else {
				vscode.window.showErrorMessage('AEM healthcheck failed. Please check your AEM instance and extension configuration settings.');
			}
		});
	}));
	context.subscriptions.push(vscode.commands.registerCommand('aempowersync.syncToAEM', (uri) => {
		isAEMRunning(function(isUp) {
			if(isUp) {
				callAEMSync(powershellexe, aemsyncscriptpath, 'put', uri, aemserver, aemcreds);
			}else {
				vscode.window.showErrorMessage('AEM healthcheck failed. Please check your AEM instance and extension configuration settings.');
			}
		});
	}));
}
exports.activate = activate;
function deactivate() {}

function callAEMSync(powershellexe, scriptpath, action, uri, aemserver, aemcreds) {
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
	// skip syncing jcr_root and /apps /content /conf
	if(uri.toString().match('[\\|/]jcr_root[\\|/](apps|content|conf)[\\|/]?$') || uri.toString().match('jcr_root[\\|/]?$')) {
		vscode.window.showErrorMessage('Invalid sync path. Please do not sync root folders.');
		return;
	}

	var niceUri = uri.toString().replace(/^.*jcr_root/,'');
	var syncfile = niceUri.split('/').pop();

	// cannot send files/folders that start with '.' or '_' to AEM instance
	if(action === 'put' && (syncfile[0] === '.' || syncfile[0] === '_')) {
		vscode.window.showErrorMessage('Cannot sync metadata files to the instance. Please sync the parent directory.');
		return;
	}
	if(action === 'get' && syncfile[0] === '_') {
		vscode.window.showErrorMessage('Cannot sync metadata files from the instance. Please sync the parent directory.');
		return;
	}

	vscode.window.showInformationMessage('aemsync started: ' + action + ' - ' + niceUri);
	syncing = true;
	var hasError = false;

	// run ps script
	var spawn = require('child_process').spawn,child;
	child = spawn(powershellexe, [
		scriptpath,
		action,
		uri,
		aemserver,
		aemcreds
	]);
	child.stdout.on('data',function(data){
		var message = (data.toString()).trim();
		psoutput.appendLine(message);
		if(message.indexOf('Error:') == 0) {
			vscode.window.showErrorMessage(message);
			hasError = true;
		}
	});
	child.stderr.on('data',function(data){
		var message = (data.toString()).trim();
		psoutput.appendLine('Error: ' + message);
		vscode.window.showErrorMessage('An error occurred. Please see the AEM PowerSync output window.');
		hasError = true;
	});
	child.on('error', (err) => {
		psoutput.appendLine(err);
		vscode.window.showErrorMessage('An error occurred. Please see the AEM PowerSync output window.');
	});
	child.on('exit',function(){
		if(hasError) {
			psoutput.appendLine('aemsync encountered an error');
		}else {
			psoutput.appendLine('aemsync completed');
			vscode.window.showInformationMessage('aemsync completed: ' + action + ' - ' + niceUri);
		}
		syncing = false;
	});
	child.stdin.end();
}

function isAEMRunning(callback) {
	var aemserver = vscode.workspace.getConfiguration('aempowersync').get('uri');
	var aemhost = aemserver.replace(/http:\/\/(.*?):.*/,'$1');
	var aemport = Number(aemserver.replace(/http:\/\/.*:(.*)/,'$1'));
	var aemhealthcheck = vscode.workspace.getConfiguration('aempowersync').get('healthcheck');
	var options = {
		host: aemhost,
		port: aemport,
		method: 'HEAD',
		path: aemhealthcheck,
		timeout: 5000
	};
	var aemreq = http.request(options, (res) => {
		// for consistency with handling a null healthcheck, moved logic to event.close
	}).on('close', () => {
		if(aemreq.res != null && aemreq.res.statusCode != null) {
			psoutput.appendLine('Healthcheck: ' + aemreq.res.statusCode + ' HEAD ' + aemserver + aemhealthcheck);
			if(aemreq.res.statusCode >= 200 && aemreq.res.statusCode < 500) {
				callback(true);
			}else {
				callback(false);
			}
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