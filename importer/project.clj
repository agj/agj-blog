(defproject importer "0.1.0-SNAPSHOT"
  :description "FIXME: write description"
  :url "http://example.com/FIXME"
  :license {:name "EPL-2.0 OR GPL-2.0-or-later WITH Classpath-exception-2.0"
            :url "https://www.eclipse.org/legal/epl-2.0/"}
  :dependencies [[org.clojure/clojure "1.11.1"]
                 [clojure.java-time "1.1.0"]
                 [clj-commons/clj-yaml "1.0.26"]
                 [org.clojure/core.match "1.0.0"]
                 [slugger "1.0.1"]
                 [hickory "0.7.1"]]
  :main ^:skip-aot importer.core
  :target-path "target/%s"
  :profiles {:uberjar {:aot :all
                       :jvm-opts ["-Dclojure.compiler.direct-linking=true"]}})
