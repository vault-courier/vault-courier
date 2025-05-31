% git clone --filter=blob:none --no-checkout https://github.com/hummingbird-project/hummingbird-examples.git
% cd hummingbird-examples
% git sparse-checkout init --cone
% git sparse-checkout set todos-postgres-tutorial
% git fetch --depth=1 origin 177dab209103bb89030a58f3e7ec0d84b6f64522
% git checkout 177dab209103bb89030a58f3e7ec0d84b6f64522