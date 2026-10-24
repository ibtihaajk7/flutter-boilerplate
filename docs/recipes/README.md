# Recipes

The template ships vendor-neutral interfaces with console-only defaults, so a
fresh copy builds and passes CI without any accounts. Each recipe plugs in a
real vendor behind the same interface: the rest of the app doesn't change.

| Recipe | Adds | Needs |
|---|---|---|
| [Firebase setup](firebase-setup.md) | `firebase_core`, `flutterfire configure` | A Firebase project. Do this first for the Firebase recipes |

Every recipe comes with its unit tests. Copy them too: the coverage gate fails
on any file under `lib/` that no test loads.

## What's already in the template

| Interface | Default | Lives in |
|---|---|---|


## Don't need a module?

Remove it with its code, tests, packages, strings and native setup:

```bash
make slim WITHOUT=notifications
```

See [Slim down](../commands.md#slim-down).
