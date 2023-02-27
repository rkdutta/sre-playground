domain="sreplayground.local"
brew install dnsmasq
mkdir -pv $(brew --prefix)/etc/
echo "address=/.$domain/127.0.0.1" >> $(brew --prefix)/etc/dnsmasq.conf
echo "cache-size=10000" >> $(brew --prefix)/etc/dnsmasq.conf

sudo brew services restart dnsmasq

sudo mkdir -pv /etc/resolver
sudo bash -c "echo 'nameserver 127.0.0.1' > /etc/resolver/$domain"
