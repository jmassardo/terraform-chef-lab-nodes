# Suppress some of the verbose output
export HAB_NONINTERACTIVE=true
# Download/Install Hab and accept license
curl https://raw.githubusercontent.com/habitat-sh/habitat/master/components/hab/install.sh | sudo bash
hab license accept

# Create Hab user group
id -u hab >/dev/null 2>&1 || sudo -E useradd hab >/dev/null 2>&1
groupadd hab
useradd -g hab hab

# Create service file for the Hab supervisor
echo [Unit] | sudo tee /etc/systemd/system/hab-sup.service
echo Description=The Chef Habitat Supervisor | sudo tee -a /etc/systemd/system/hab-sup.service
echo [Service] | sudo tee -a /etc/systemd/system/hab-sup.service
echo ExecStart=/bin/hab sup run | sudo tee -a /etc/systemd/system/hab-sup.service
echo [Install] | sudo tee -a /etc/systemd/system/hab-sup.service
echo WantedBy=default.target | sudo tee -a /etc/systemd/system/hab-sup.service

# Load up and start the service
sudo -E systemctl daemon-reload
sudo -E systemctl start hab-sup
sudo -E systemctl enable hab-sup

# Let's make sure the supervisor is listening before we move on
until sudo -E hab svc status > /dev/null
do
  echo "Waiting 5 seconds for supervisor to finish loading"
  sleep 5
done