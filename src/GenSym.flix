eff GenSym {
    def next(): Int32
}

mod GenSym {

    pub def runWithRef(ref: Ref[Int32, r], f: Unit -> a \ ef): a \ (ef - GenSym) + r = {
        run f() with handler GenSym {
            def next(k) = {
                let current = Ref.get(ref);
                ref |> Ref.transform(i -> i + 1);
                k(current)
            }
        }
    }
}