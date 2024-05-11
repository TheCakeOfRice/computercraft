# Inventory scalability
- Inventory function scales poorly with the amount of items stored
- Could implement "cold storage" to reduce overhead for frequent refreshes
- Integrate RS Bridge from Advanced Peripherals

# Power (RF) Monitor Interface
- I/O rate
- Total RF banked
- On/Off button

# Scalable pod of crafty turtles
- Add a new CPU - CraftCPU which manages a network of crafty turtles (& machines)
- Use export API and queueing to facilitate pushing items to the crafty turtles
- Manage "busy" and "free" states (redstone lamps would be cool to see this visually)
- List of craftable items could persist between servers