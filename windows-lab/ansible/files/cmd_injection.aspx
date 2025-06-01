<%@ Page Language="C#" Debug="true" %>
<%@ Import Namespace="System.Diagnostics" %>
<script runat="server">
    void Page_Load(object sender, EventArgs e)
    {
        if (Request.Form["target"] != null)
        {
            string target = Request.Form["target"].ToString();
            
            Response.Write("<div class='result-section'>");
            Response.Write("<h3>🔍 Network Connectivity Test Results</h3>");
            Response.Write("<div class='command-info'>Testing connectivity to: <strong>" + Server.HtmlEncode(target) + "</strong></div>");
            
            // Vulnerable: Direct command injection in ping command
            string command = "ping -n 4 " + target;
            Response.Write("<div class='command-executed'>Command: <code>" + Server.HtmlEncode(command) + "</code></div>");
            
            Response.Write("<pre class='output'>");
            try
            {
                Process p = new Process();
                p.StartInfo.FileName = "cmd.exe";
                p.StartInfo.Arguments = "/c " + command;
                p.StartInfo.RedirectStandardOutput = true;
                p.StartInfo.RedirectStandardError = true;
                p.StartInfo.UseShellExecute = false;
                p.StartInfo.CreateNoWindow = true;
                p.Start();
                
                string output = p.StandardOutput.ReadToEnd();
                string error = p.StandardError.ReadToEnd();
                p.WaitForExit();
                
                if (!string.IsNullOrEmpty(output))
                    Response.Write(Server.HtmlEncode(output));
                if (!string.IsNullOrEmpty(error))
                    Response.Write("\nERROR:\n" + Server.HtmlEncode(error));
            }
            catch (Exception ex)
            {
                Response.Write("Execution failed: " + Server.HtmlEncode(ex.Message));
            }
            Response.Write("</pre>");
            Response.Write("</div>");
        }
    }
</script>
<!DOCTYPE html>
<html>
<head>
    <title>SecureCorp - Network Diagnostics Portal</title>
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 0; 
            padding: 0; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        .container { 
            max-width: 1000px; 
            margin: 0 auto; 
            background: white; 
            min-height: 100vh;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }
        .header { 
            background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%); 
            color: white; 
            padding: 25px; 
            text-align: center;
        }
        .header h1 { margin: 0; font-size: 28px; }
        .header p { margin: 5px 0 0 0; opacity: 0.9; }
        .content { padding: 30px; }
        .tool-section { 
            background: #f8f9fa; 
            padding: 25px; 
            border-radius: 8px; 
            margin-bottom: 20px;
            border-left: 4px solid #007bff;
        }
        .form-group { margin-bottom: 20px; }
        .form-group label { 
            display: block; 
            margin-bottom: 8px; 
            font-weight: 600; 
            color: #333;
        }
        .form-group input[type="text"] { 
            width: 70%; 
            padding: 12px; 
            border: 2px solid #ddd; 
            border-radius: 6px; 
            font-size: 14px;
            transition: border-color 0.3s;
        }
        .form-group input[type="text"]:focus {
            outline: none;
            border-color: #007bff;
            box-shadow: 0 0 0 3px rgba(0,123,255,0.1);
        }
        .btn { 
            background: linear-gradient(135deg, #007bff 0%, #0056b3 100%); 
            color: white; 
            padding: 12px 25px; 
            border: none; 
            border-radius: 6px; 
            cursor: pointer; 
            font-size: 14px;
            font-weight: 600;
            transition: transform 0.2s;
        }
        .btn:hover { 
            transform: translateY(-1px); 
            box-shadow: 0 4px 12px rgba(0,123,255,0.3);
        }
        .examples { 
            background: #e7f3ff; 
            padding: 15px; 
            border-radius: 6px; 
            margin: 15px 0;
            border-left: 4px solid #007bff;
        }
        .security-notice { 
            background: #fff3cd; 
            border: 1px solid #ffeaa7; 
            color: #856404; 
            padding: 15px; 
            border-radius: 6px; 
            margin: 15px 0;
        }
        .result-section {
            background: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 8px;
            margin: 20px 0;
            padding: 20px;
        }
        .command-info {
            background: #d4edda;
            color: #155724;
            padding: 10px;
            border-radius: 4px;
            margin: 10px 0;
        }
        .command-executed {
            background: #cce7ff;
            color: #004085;
            padding: 8px;
            border-radius: 4px;
            margin: 10px 0;
            font-family: monospace;
        }
        .output { 
            background: #1e1e1e; 
            color: #ffffff; 
            padding: 20px; 
            border-radius: 6px; 
            font-family: 'Consolas', 'Monaco', monospace; 
            white-space: pre-wrap;
            overflow-x: auto;
            border: 1px solid #333;
        }
        .footer { 
            text-align: center; 
            padding: 20px; 
            color: #6c757d; 
            font-size: 12px;
            background: #f8f9fa;
            border-top: 1px solid #dee2e6;
        }
        .feature-list {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }
        .feature-item {
            background: white;
            padding: 15px;
            border-radius: 6px;
            border: 1px solid #e9ecef;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🌐 SecureCorp Network Diagnostics</h1>
            <p>Infrastructure Monitoring & Connectivity Testing Portal</p>
        </div>
        
        <div class="content">
            <div class="tool-section">
                <h3>🔧 Network Connectivity Tester</h3>
                <p>Test network connectivity to internal and external hosts using ICMP ping.</p>
                
                <form method="post" action="cmd_injection.aspx">
                    <div class="form-group">
                        <label for="target">🎯 Target Host or IP Address:</label>
                        <input type="text" id="target" name="target" 
                               placeholder="Enter hostname or IP (e.g., google.com, 8.8.8.8)"
                               value="<%= Request.Form["target"] != null ? Server.HtmlEncode(Request.Form["target"]) : "google.com" %>">
                        <input type="submit" value="🚀 Test Connectivity" class="btn">
                    </div>
                </form>
                
                <div class="examples">
                    <strong>📋 Common Test Targets:</strong><br>
                    <code>google.com</code> • <code>8.8.8.8</code> • <code>localhost</code> • 
                    <code>192.168.1.1</code> • <code>securecorp.local</code>
                </div>
                
                <div class="security-notice">
                    ⚠️ <strong>Security Notice:</strong> This tool uses ping command to test connectivity. 
                    Only authorized network administrators should use this diagnostic tool.
                </div>
            </div>
            
            <div class="feature-list">
                <div class="feature-item">
                    <strong>🏃‍♂️ Real-time Testing</strong><br>
                    <small>Live network connectivity checks</small>
                </div>
                <div class="feature-item">
                    <strong>📊 Detailed Results</strong><br>
                    <small>Comprehensive ping statistics</small>
                </div>
                <div class="feature-item">
                    <strong>🔒 Secure Access</strong><br>
                    <small>Admin-only diagnostic tools</small>
                </div>
                <div class="feature-item">
                    <strong>⚡ Fast Response</strong><br>
                    <small>Quick network analysis</small>
                </div>
            </div>
        </div>
        
        <div class="footer">
            SecureCorp IT Infrastructure Team • Network Diagnostics v3.2.1 • Build 2024.03.15
        </div>
    </div>
</body>
</html> 