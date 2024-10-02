# One-Shot Protection
This addon gives players the ability to be protected from one-shot kills,
similar to the mechanic of the same name in the game _Risk of Rain 2_.
A lot of the addon's behavior can be modified with [hooks](#hooks) in Lua.

> [!NOTE]
> The code is not intended to be included in gamemode code; consider writing
> your own version of one-shot protection which would be better suited for your
> specific use case.

# Console variables
To set a console variable, simply type `console_variable_name "variable_value"`
in the console, or create a `.cfg` file in the `garrysmod/cfg` directory.
A list of ConVars provided by the addon follows.
## `mp_one_shot_protection`
`1` enables the mechanic, `0` disables it.
## `mp_one_shot_invuln_period`
Numeric value indicates the period in seconds of invulnerability after a
one-shot protection.
## `mp_one_shot_health_threshold`
Numeric value indicates the multiplier of the effective maximum health above
which something is eligible for one-shot protection.
## `mp_one_shot_health_protected`
Numeric value indicates the multiplier of the effective maximum health which
will be left for something after it has been protected from a one-shot kill.

# Hooks
To not make the addon an unmodifiable monolith at run-time, some custom hooks
can be used in order to customize its behavior.
A list of hooks provided by the addon, along with their pseudo-signatures,
follows.
## `OneShotProtection_IsProtected`
```
IsProtected(target: Entity, dmg_info: CTakeDamageInfo) -> boolean?
```
The addon needs to know whether `target` is protected from one-shot kills given
`dmg_info`.

Return `true` if it most definitely is, or `false` or _preferably `nil`_ to
indicate that it isn't.
## `OneShotProtection_CalcEffectiveHealth`
```
CalcEffectiveHealth(target: Entity) -> (number, number)?
```
The addon needs to know the effective health and maximum health of `target`.

Return `health, health_max` to override the default calculation, or `nil`
otherwise.
## `OneShotProtection_CalcHealthThreshold`
```
CalcHealthThreshold(
	health_max: number,
	target: Entity, health: number
) -> number?
```
The addon needs to know the health threshold for `target` given its effective
`health` and `health_max`.

Return a `number` to override the default calculation, or `nil` otherwise.
## `OneShotProtection_CalcHealthProtected`
```
CalcHealthProtected(
	health_max: number,
	target: Entity, health: number
) -> number?
```
The addon needs to know the minimum health to be left for `target` after
one-shot protection given its effective `health` and `health_max`.

Return a `number` to override the default calculation, or `nil` otherwise.
## `OneShotProtection_DoProtect`
```
DoProtect(
	dmg_info: CTakeDamageInfo,
	health: number, health_protected: number, health_max: number,
	target: Entity
) -> (true|false|"block")?
```
The addon needs to do one-shot protection for `target`, which would involve
tweaking the damage in `dmg_info` to make `target` have `health_protected`
effective health left afterwards, given its effective `health` and `health_max`.

Return `true` to indicate that you've done the protection yourself, `false` to
exit, `"block"` to block the damage event, or `nil` to pass through to other
hooks.
## `OneShotProtection_CalcInvulnExpireTime`
```
CalcInvulnExpireTime(
	target: Entity, dmg_info: CTakeDamageInfo,
	health: number, health_max: number, health_protected: number
) -> number?
```
`target` was protected from a one-shot kill given `dmg_info`, with its effective
`health` and `health_max`, reducing its effective health to `health_protected`;
the addon now needs to know the time (based on `CurTime`) when the
invulnerability expires.

Return a `number` to override the default expiry time, or `nil` otherwise.
## `OneShotProtection_Protected`
```
Protected(
	target: Entity, dmg_info: CTakeDamageInfo,
	health: number, health_max: number, health_protected: number
)
```
`target` was protected from a one-shot kill given `dmg_info`, with its effective
`health` and `health_max`, reducing its effective health to `health_protected`.

Preferably, do not return any values in this hook to let other hooks run.
