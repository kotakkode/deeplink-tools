## 0.1.0

- Initial release: floating button, env switcher, deeplinks saved as
  env + name + URL, in-app inject / app callback / OS launch dispatch,
  on-the-fly CRUD with undo, JSON profile import/export, runtime icon presets.
- `showEnvSelector` config flag to hide the env UI and lock the tester to a
  single environment. The env UI also hides itself while there are fewer than
  two envs.
- Panel title shows the active env: `Current Active Env : DEV`.
