use strict;
use warnings;

use Test::More;

use ZMQ::FFI;
use ZMQ::FFI::Constants qw(:all);
use ZMQ::FFI::Util qw(zmq_version);

subtest 'ctx version',
sub {
    my $ctx = ZMQ::FFI->new();

    is_deeply
        [zmq_version()],
        [$ctx->version()],
        'util version and ctx version match';
};

subtest 'ctx options',
sub {

    plan skip_all =>
        "libzmq 2.x found, don't test 3.x style ctx options"
        if (zmq_version())[0] == 2;

    my $ctx = ZMQ::FFI->new( threads => 42, max_sockets => 42 );

    is $ctx->get(ZMQ_IO_THREADS),  42, 'threads set to 42';
    is $ctx->get(ZMQ_MAX_SOCKETS), 42, 'max sockets set to 42';

    $ctx->set(ZMQ_IO_THREADS, 1);
    $ctx->set(ZMQ_MAX_SOCKETS, 1024);

    is $ctx->get(ZMQ_IO_THREADS),     1, 'threads set to 1';
    is $ctx->get(ZMQ_MAX_SOCKETS), 1024, 'max sockets set to 1024';
};

subtest 'socket options',
sub {
    my $ctx = ZMQ::FFI->new();
    my $s   = $ctx->socket(ZMQ_REQ);

    is $s->get_linger(), -1, 'got default linger';

    $s->set_linger(42);
    is $s->get_linger(), 42, 'set linger';

    is $s->get_identity(), undef, 'got default identity';

    $s->set_identity('foo');
    is $s->get_identity(), 'foo', 'set identity';
};

subtest 'uint64_t options',
sub {
    use bigint;

    my $max_uint64 = 2**64-1;
    my $ctx        = ZMQ::FFI->new();

    my $s = $ctx->socket(ZMQ_REQ);

    $s->set(ZMQ_AFFINITY, 'uint64_t', $max_uint64);
    is $s->get(ZMQ_AFFINITY, 'uint64_t'), $max_uint64,
        'set/got max unsigned 64 bit int option value';

    no bigint;
};

subtest 'int64_t options',
sub {
    use bigint;

    # max negative 64bit values don't currently make
    # sense with any zmq opts, so we'll stick with positive
    my $max_int64 = 2**63-1;
    my $ctx       = ZMQ::FFI->new();

    my ($major) = $ctx->version;

    my $opt;
    if ($major == 2) {
        $opt = ZMQ_RECOVERY_IVL_MSEC;
    }
    elsif ($major == 3) {
        $opt = ZMQ_MAXMSGSIZE;
    }
    else {
        die "Unsupported zmq version $major";
    }

    my $s = $ctx->socket(ZMQ_REQ);

    is $s->get($opt, 'int64_t'), -1,
        'got default option value';

    $s->set($opt, 'int64_t', $max_int64);
    is $s->get($opt, 'int64_t'), $max_int64,
        'set/got max signed 64 bit int option value';

    no bigint;
};

done_testing;
