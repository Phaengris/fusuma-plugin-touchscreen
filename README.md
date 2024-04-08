# Fusuma::Plugin::Touchscreen

**Unfortunately I'm overloaded and have no time to work on / support the project now. Feel free to fork it if you're interested. It may be resumed it in the future but really can't promise atm.**

The Fusuma plugin for touchscreens.

## Fusuma

Fusuma is a multitouch gesture recognizer for Linux desktops.
You can read more about it on [the Fusuma GitHub page](https://github.com/iberianpig/fusuma).

This plugin adds support for touchscreens.

## Installation

First you need to [install Fusuma](https://github.com/iberianpig/fusuma#installation).

Then the plugin can be installed as [any other Fusuma plugin](https://github.com/iberianpig/fusuma#fusuma-plugins):

```bash
sudo gem install fusuma-plugin-touchscreen
```

## Configuration

If your Fusuma is already configured, you don't need to do anything else.
The plugin uses the very same configuration file / entries.

(So yes, your touchpad and your touchscreen will share the same gestures.)

Read more [how to configure Fusuma](https://github.com/iberianpig/fusuma#customize-gesture-mapping).

## Supported features

Tap, Hold, Swipe, Pinch, Rotate.

One or more fingers, as many as your device supports (through libinput).

begin / update / end events (for all but Tap of course). 

## Known issues

As Fusuma itself, this plugin depends on the output of the `libinput debug-events`
command which may be unstable.

It is a plan to write some code to interact with libinput directly,
but that's a task for the future.

Threshold options are hard-coded and not configurable yet. That would be the next step.

## Possible issues

This plugin is tested on Microsoft Surface Pro 3 only.
If you can test it on other devices, please share your experience.

## Contributing

Bug reports and pull requests are welcome
on GitHub at https://github.com/Phaengris/fusuma-plugin-touchscreen

This project is intended to be a safe, welcoming space for collaboration,
and contributors are expected to adhere to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Fusuma::Plugin::Touchscreen project’s codebases,
issue trackers, chat rooms and mailing lists is expected to follow
the [code of conduct](https://github.com/iberianpig/fusuma-plugin-tap/blob/master/CODE_OF_CONDUCT.md).
