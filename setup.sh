#!/bin/bash

# check if jq is installed, if not, prompt the user if they want to install it and if so, install it for them, else exit if the user says no
if ! [ -x "$(command -v jq)" ]; then
    read -p "Do you want to install jq? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Installing jq..."
        # use apt if linux, brew if mac
        if [[ "$OSTYPE" == "linux-gnu" ]]; then
            sudo apt-get install jq
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install jq
        fi
    else
        echo "Exiting..."
        exit 1
    fi
fi

# check if composer is installed, if not, prompt the user if they want to install it and if so, install it for them, else exit if the user says no
if ! [ -x "$(command -v composer)" ]; then
    read -p "Do you want to install composer? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Installing composer..."

        # use apt if linux, brew if mac
        if [[ "$OSTYPE" == "linux-gnu" ]]; then
            sudo apt-get install composer
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install composer
        fi
    else
        echo "Exiting..."
        exit 1
    fi
fi


# check if the user is in the root directory of their project, if not, prompt the user if they want to change to the root directory and if so, change to it, else


# run composer init to create a composer.json file if it doesn't exist
if ! [ -f composer.json ]; then
    composer init
fi

# Install phpunit
composer require --dev phpunit/phpunit

# Extract the namespace from the composer.json file
json=$(cat composer.json)
namespace=$(echo $json | jq -r '.autoload."psr-4" | keys[0]')

# remove the trailing slash from the namespace
namespace=$(echo $namespace | sed 's/.$//')

echo $namespace


# Create an example Hello World class and matching phpunit test
mkdir -p src tests
cat > src/Example.php <<EOF
<?php

namespace $namespace;

class Example
{
    public function sayHello()
    {
        return 'Hello World';
    }
}
EOF

cat > tests/ExampleTest.php <<EOF
<?php

namespace $namespace;

use PHPUnit\Framework\TestCase;

class ExampleTest extends TestCase
{
    public function testSayHello()
    {
        \$example = new Example();
        \$this->assertEquals('Hello World', \$example->sayHello());
        \$this->assertNotEquals('Sandwich', \$example->sayHello());
    }
}
EOF



# Create a run_tests.sh script
cat > run_tests.sh <<EOF
#!/bin/bash
# check if ./vendor/bin/phpunit is installed, if not, prompt the user to run the setup.sh script again and exit
if ! [ -x "$(command -v ./vendor/bin/phpunit)" ]; then
    echo "Please run the setup.sh script again to install phpunit"
    exit 1
fi

./vendor/bin/phpunit tests/*
EOF
chmod 750 run_tests.sh

# run the phpunit test using run_tests.sh
./run_tests.sh

# check the exit code of the phpunit test and if it was a failure, tell the user and exit
if [ $? -eq 1 ]; then
    echo "Failure executing initial unit test!"
    exit 1
fi

# Create a .gitignore file with basic ignores for a php project
cat > .gitignore <<EOF
# Ignore composer dependencies
/vendor
.DS_Store
EOF

# Create a README.md file
cat > README.md <<EOF
# $namespace
EOF

# initalize the git repo if it is not already
if ! [ -d .git ]; then
    git init
fi