<h1 align="center">
 <img src="zero-banner.png" style="height: 100px">
  <p>zero</p>
</h1>


[zero](https://tedius-git.github.io/zero/) graphing calculator made with elm
 
<img src="screenshot.png" style="height: 400px">

## TODO

- [ ] Unique naming
- [ ] Automatic naming
- [ ] aritmetic operations (+,-,*,/)
- [ ] variable declarations

## Development

### Nix

The proyect includes a flake.nix with a devshell with the dependencies. Run:

```bash
# Clone the repo
git clone https://github.com/tedius-git/zero.git

# Enter the devshell
nix develop

# Build and watch for changes
zero-dev

# Dev server 
elm reactor
```

