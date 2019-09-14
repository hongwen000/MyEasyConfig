function coding
	set days $argv[1]
    set repo_path "/Users/lixinrui/code_snip/"
    if not test $days
        set name (gdate +"%Y-%m-%d")
    else
        set name (gdate -d "$days day ago" +"%Y-%m-%d")
    end
if ll $repo_path | grep $name
cd $repo_path$name
else
mkdir $repo_path$name
cd $repo_path$name
end
end
