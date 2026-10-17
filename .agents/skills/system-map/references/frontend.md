# Frontend System Analysis

Analyze frontend systems through user interaction, state, rendering, and side effects.

## Primary Flow

User Action
→ Event Handler
→ State Change
→ Derived State
→ Render
→ Async Effect
→ Server Response
→ State Update
→ Re-render

## Investigate

### Entry
- Route
- Component mount
- User event
- Browser event

### State
Classify:
- Local component state
- Shared/global state
- Server state/cache
- URL state
- Derived state

For each state identify owner, mutation path, lifetime, and persistence.

### Data Flow

Trace:

Server/API Data → Client Cache → State → Props → Component → UI

### Side Effects
Identify:
- Network requests
- Subscriptions
- Timers
- Browser storage
- Event listeners

### Lifecycle
Trace mount → initialization → active updates → cleanup → unmount.

### Performance
Look for:
- Unnecessary re-renders
- Expensive derived state
- Large lists
- Waterfall requests
- State fan-out

The goal is to explain how user actions become state transitions and visible UI changes.
