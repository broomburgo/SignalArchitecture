# SignalArchitecture

An architectural pattern for iOS development, for decoupling view controllers from their model and their users by using **signals**. And then more stuff with signals.

A *Signal* is a box that will possibly contain a value at multiple points in time: the press of a UIButton, for example, could be considered a signal, because it will possibly be tapped at several points in time, and each tap can be considered a **ON** value.

Thus, we could observe a *buttonTapSignal*, that will trigger a callback each time the very button is tapped

Now consider a view controller used, for example, to select a photo from a UICollectionView, for editing purposes: there could be a *photoSelectedSignal* which *boxed value* is the photo itself.

This is different from the classic delegation pattern because multiple objects could observe the same signal, and the signal itself is an object that can be stored, passed around and transformed.

The project will contain a small framework to get started with signals, with commented code for educational purposes: then, an architectural pattern is proposed, based on signals, to manage the presentation and lifetime of view controllers.

The project is ongoing and not yet complete, so please stay tuned.
