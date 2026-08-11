-- APIServer is no longer required. Keep this role as a migration aid so old
-- worlds explain what changed instead of silently failing.
peripheral.find("modem", rednet.open)
print("APIServer has been merged into StorageCPU.")
print("Install/update StorageCPU, then repurpose this computer as a worker.")
while true do os.pullEvent() end
