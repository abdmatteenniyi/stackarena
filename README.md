# Stack Arena

A decentralized PvP battle game on the Stacks blockchain where heroes compete for glory and rewards.

## Overview

Stack Arena is an on-chain smart contract that allows players to:
- **Create Heroes** - Register custom heroes with unique names
- **Battle Other Heroes** - Compete in turn-based PvP matches
- **Earn Rewards** - Win battles to gain power and prestige
- **Upgrade Stats** - Invest STX to improve your hero's abilities
- **Heal Between Battles** - Restore health for a fee

## Game Mechanics

### Hero Stats
- **Power**: Determines attack damage (base 10)
- **Defense**: Reduces incoming damage (base 5)
- **Health**: Hero's remaining vitality (base 100)
- **Wins/Losses**: Battle record tracking

### Battle System
- Players pay a match fee (1 STX) to enter battle
- Winner receives 2x the match fee pool
- Health decreases by 10 per loss
- Hero dies when health reaches 0
- Randomized attack calculations for fairness

### Costs
- **Match Fee**: 1 STX per battle
- **Heal Cost**: 0.5 STX to restore to full health
- **Upgrade Cost**: 2 STX to increase power and defense by +2

