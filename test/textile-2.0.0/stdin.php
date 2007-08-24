<?php

require_once('classTextile.php');

$textile = new Textile();

$in = '';
while (!feof(STDIN)) {
  $in .= fread(STDIN, 8192);
}
fclose(STDIN);

fwrite(STDOUT, $textile->TextileThis($in));

exit(0); 

?>
