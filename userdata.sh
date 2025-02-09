# #!/bin/bash
# sudo apt-get update
# sudo apt-get install apache2 -y
# sudo systemctl start apache2
# sudo systemctl enable apache2
# hostname | sudo tee /var/www/html/index.html

#!/bin/bash
sudo apt update
sudo apt install -y apache2

# Get the instance ID using the instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Install the AWS CLI
sudo apt install -y awscli

# Start Apache and enable it on boot
sudo systemctl start apache2
sudo systemctl enable apache2

# Create a simple HTML file with the portfolio content and display the images
sudo tee /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
  <title>My Portfolio</title>
  <style>
    /* Add animation and styling for the text */
    @keyframes colorChange {
      0% { color: red; }
      50% { color: green; }
      100% { color: blue; }
    }
    h1 {
      animation: colorChange 2s infinite;
    }
  </style>
</head>
<body>
  <h1>Terraform Project Server 1</h1>
  <h2>Instance ID: <span style="color:green">$INSTANCE_ID</span></h2>
  <p>Welcome to US-EAST</p>
  
</body>
</html>
EOF

# Start Apache and enable it on boot
sudo systemctl start apache2
sudo systemctl enable apache2