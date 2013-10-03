package ZMQ::FFI::ZMQ2::Socket;

use Moo;
use namespace::autoclean;

use FFI::Raw;

extends q(ZMQ::FFI::SocketBase);

with q(ZMQ::FFI::SocketRole);

my $zmq_msg_init = FFI::Raw->new(
    'libzmq.so' => 'zmq_msg_init',
    FFI::Raw::int, # retval
    FFI::Raw::ptr, # zmq_msg_t ptr
);

my $zmq_msg_data = FFI::Raw->new(
    'libzmq.so' => 'zmq_msg_data',
    FFI::Raw::ptr, # msg data ptr
    FFI::Raw::ptr  # msg ptr
);

my $zmq_msg_close = FFI::Raw->new(
    'libzmq.so' => 'zmq_msg_data',
    FFI::Raw::int, # retval
    FFI::Raw::ptr  # msg ptr
);

my $memcpy = FFI::Raw->new(
    'libc.so.6' => 'memcpy',
    FFI::Raw::ptr,  # dest filled
    FFI::Raw::ptr,  # dest buf
    FFI::Raw::ptr,  # src
    FFI::Raw::int   # buf size
);

my $zmq_msg_size = FFI::Raw->new(
    'libzmq.so' => 'zmq_msg_size',
    FFI::Raw::int, # returns msg size in bytes
    FFI::Raw::ptr  # msg ptr
);

my $zmq_recv = FFI::Raw->new(
    'libzmq.so' => 'zmq_recv',
    FFI::Raw::int, # retval
    FFI::Raw::ptr, # socket ptr
    FFI::Raw::ptr, # msg ptr
    FFI::Raw::int  # flags
);

sub recv {
    my ($self, $flags) = @_;

    $flags //= 0;

    my $msg_ptr = FFI::Raw::memptr(40); # large enough to hold zmq_msg_t

    zcheck_error('zmq_msg_init', $zmq_msg_init->($msg_ptr));
    zcheck_error('zmq_recvmsg', $zmq_recv->($self->_socket, $msg_ptr, $flags));

    my $data_ptr    = $zmq_msg_data->($msg_ptr);

    my $msg_size = zcheck_error(
        'zmq_msg_size',
        $zmq_msg_size->($msg_ptr)
    );

    my $content_ptr = FFI::Raw::memptr($msg_size);

    $memcpy->($content_ptr, $data_ptr, $msg_size);

    $zmq_msg_close->($msg_ptr);
    return $content_ptr->tostr($msg_size);
}

__PACKAGE__->meta->make_immutable();
