const vscode = require('vscode');
const http = require('http');
const { url } = require('inspector');
const config = require("./aempowersync.json");

var syncing = false;
var osgiEnabled = false;
var psoutput;

/**
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {

	// reference script from extensions folder
	var aemsyncscriptpath = context.extensionPath + '\\aemsync.ps1';

	// config
	var powershellexe = vscode.workspace.getConfiguration('aempowersync').get('powershell');

	psoutput = vscode.window.createOutputChannel('AEM PowerSync');
	psoutput.appendLine('AEM PowerSync is now active!');

	var enabledOsgiConfig = vscode.workspace.getConfiguration('aempowersync').get('enableOsgiConfig');
	osgiEnabled = !enabledOsgiConfig;

	// register commands
	context.subscriptions.push(vscode.commands.registerCommand('aempowersync.syncFromAEM', (uri) => {
		if(syncing) {
			vscode.window.showInformationMessage('Please wait for the current sync to complete before starting a new one.');
			return;
		}else {
			isAEMRunning(function(isUp) {
				if(isUp) {
					if(!osgiEnabled) {
						enableOSGIConfig(function(success) {
							if(success) {
								osgiEnabled = true;
								callAEMSync(powershellexe, aemsyncscriptpath, 'get', uri);
							}
						});
					}else {
						callAEMSync(powershellexe, aemsyncscriptpath, 'get', uri);
					}
				}else {
					vscode.window.showErrorMessage('AEM healthcheck failed. Please check your AEM instance and extension configuration settings.');
				}
			});
		}
	}));
	context.subscriptions.push(vscode.commands.registerCommand('aempowersync.syncToAEM', (uri) => {
		if(syncing) {
			vscode.window.showInformationMessage('Please wait for the current sync to complete before starting a new one.');
			return;
		}else {
			isAEMRunning(function(isUp) {
				if(isUp) {
					if(!osgiEnabled) {
						enableOSGIConfig(function(success) {
							if(success) {
								osgiEnabled = true;
								callAEMSync(powershellexe, aemsyncscriptpath, 'put', uri);
							}
						});
					}else {
						callAEMSync(powershellexe, aemsyncscriptpath, 'put', uri);
					}
				}else {
					vscode.window.showErrorMessage('AEM healthcheck failed. Please check your AEM instance and extension configuration settings.');
				}
			});
		}
	}));
}
exports.activate = activate;
function deactivate() {}

function callAEMSync(powershellexe, scriptpath, action, uri) {
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
		vscode.workspace.getConfiguration('aempowersync').get('uri'),
		vscode.workspace.getConfiguration('aempowersync').get('credentials'),
		vscode.workspace.getConfiguration('aempowersync').get('use7z')
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

function enableOSGIConfig(callback) {
	let reqs = 0;
	config.osgiConfig.forEach(function(c) {
		updateOSGIComponent(c, function(res) {
			if(res < 400) {
				reqs++;
			}else if(res < 500) {
				vscode.window.showErrorMessage('Invalid AEM user credentials. Please check your AEM instance and extension configuration settings.');
			}else {
				vscode.window.showErrorMessage('Server error. Please check your AEM instance and extension configuration settings.');
			}
			if(reqs == config.osgiConfig.length) {
				psoutput.appendLine("AEM OSGi configuration updated successfully.");
				callback(true);
				return;
			}
		});
	});
	callback(false);
}

function updateOSGIComponent(osgiJson, callback) {
	let creds = vscode.workspace.getConfiguration('aempowersync').get('credentials');
	if(typeof creds === "undefined" || creds == "") {
		callback(false);
	}else {
		var aemserver = vscode.workspace.getConfiguration('aempowersync').get('uri');
		var aemhost = aemserver.replace(/http:\/\/(.*?):.*/,'$1');
		var aemport = Number(aemserver.replace(/http:\/\/.*:(.*)/,'$1'));
		let auth = "Basic " + Buffer.from(creds).toString("base64");
		let data = osgiJson.data;

		let options = {
			host: aemhost,
			port: aemport,
			path: osgiJson.path,
			method: "POST",
			timeout: 5000,
			headers: {
				"Content-Type": "application/x-www-form-urlencoded",
				"Authorization": auth,
				"Content-Length": Buffer.byteLength(data)
			}
		};

		try {
			const aemreq = http.request(options, (res) => {
				psoutput.appendLine("updateOSGIConfig " + osgiJson.path + " " + res.statusCode);
				callback(res.statusCode);
				//res.on("data", (chunk) => {});
				res.on("close", () => {});
			});
			aemreq.on("error", (error) => {
				psoutput.appendLine("updateOSGIConfig error: " + error);
			});
			aemreq.write(data);
			aemreq.end();
		}catch(e) {
			psoutput.appendLine("updateOSGIConfig error: " + e);
		}
	}
}

module.exports = {
	activate,
	deactivate
}