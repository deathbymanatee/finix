# Comparison of `finix` and NixOS

On the surface, `finix` and NixOS present a lot of similarities: `finix` utilizes the module system of `nix` in a very similar fashion to NixOS. It has identical syntax for enabling programs and services as NixOS. However, as alluded to in the introductary page, there is one key difference that distinguishes `finix` vs NixOS. At a baseline, NixOS and all of its modules are automatically imported into the global configuration attribute set by default. A benefit to this approach is that the end user does not need to manually maintain a list of imports for modules they would like to enable, but it comes at a significant cost to evaluation times, since every single NixOS module is evaluated. `finix` opts for a set of minimal defaults, shifting the responsibility over to the end user to maintain their own import list. 

Here is an example of what that looks like in practice. 

Say a user would like to enable the service module for `chrony`, a network time synchronization daemon. Under NixOS, it would be as simple as adding this line to your `configuration.nix`:

```nix
{ config, ... }:
{
  # ...
  services.chrony.enable = true;
  # ...
}
```

If a user wanted to do the same on `finix`, they would first need to add an `imports` statement, along with an extra function input at the top of their configuration file. Like so:

```nix
{ 
  config, 
  modules, # finix-specific
  ...
}:
{
  imports = [ modules.chrony ];
  services.chrony.enable = true;
}
```


