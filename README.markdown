# MGTileMenu

by Matt Gemmell

- [Visit mattgemmell.com](http://mattgemmell.com/)
- [Follow @mattgemmell on Twitter](http://twitter.com/mattgemmell)



## What is MGTileMenu?

MGTileMenu is an iOS GUI component, providing a pop-up tile-based contextual menu. It's designed for iOS 5, and uses ARC. It supports Retina and non-Retina devices, and works with VoiceOver. MGTileMenu is designed for use on iPad, but it will also work on iPhone and iPod touch.

You can [read all about MGTileMenu (and its design) here](http://mattgemmell.com/2012/05/14/mgtilemenu/).

MGTileMenu is released under an attribution license for free, and can also be licensed without the attribution requirement for a modest fee. MGTileMenu has no external dependencies.

Tile menus show five icon-tiles per 'page', with a sixth page-switching tile ("...") used to switch to successive pages of tiles. You can have any number of pages of tiles.

The placement of the page-switching tile depends on whether MGTileMenu is configured to be right-handed (the default) or left-handed, and will leave a gap for your finger in each case.

You can extensively configure MGTileMenu's behaviour and appearance. There's a delegate protocol to supply tile icons, and to customise tile backgrounds (with images, gradients or flat colours). MGTileMenu also posts various notifications which may be useful.

MGTileMenu is designed with convenience in mind. Its default appearance and behaviour have been configured to suit most situations, and it will try to behave intelligently to minimise the work you have to do when using it (for example, it will sanity-check and adjust the position you tell it to display at, to ensure it's fully visible, and will move to remain visible when the device rotates).

The controller's own properties and methods, and the delegate protocol, have similarly been designed for maximum convenience. You should find MGTileMenu very easy to integrate and use, with minimal additional effort.



## Getting started

MGTileMenu includes a demo application, showing how to create and configure an example menu.

Essentially, MGTileMenu is a UIViewController subclass with a simple (and required) delegate protocol. It's used by instantiating the controller, then calling its `displayMenuCenteredOnPoint:inView:` method.

The files you'll need to copy into your own project are in the 'MGTileMenu' group in the Xcode project. There are 5 code files and 3 images. They are:

- MGTileMenuController.h and .m
- MGTileMenuDelegate.h
- MGTileMenuView.h and .m
- CloseButton.png, CloseButton@2x.png, and ellipsis@2x.png

The remaining files in the Xcode project are included for demonstration purposes only. With the exception of the Instinctive Code logo PNG images, you're welcome to use them as you see fit.



## Downloading the code

You can [get MGTileMenu on github](http://github.com/mattgemmell/MGTileMenu).



## License

MGTileMenu is released under its own attribution license (which is included with the source code). You can also purchase a non-attribution license if you wish, via my [online license store](http://sites.fastspring.com/mattgemmell/product/sourcecode).



## Support, bugs and feature requests

There is absolutely **no support** offered with this component. You're on your own! If you want to submit a feature request, please do so via [the issue tracker on github](http://github.com/mattgemmell/MGTileMenu/issues).

If you want to submit a bug report, please also do so via the issue tracker, including a diagnosis of the problem and a suggested fix (in code). If you're using MGTileMenu, you're a developer - so I expect you to do your homework and provide a fix along with each bug report. You can also submit pull requests or patches.

Please don't submit bug reports without fixes!
