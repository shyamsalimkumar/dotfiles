set nocompatible              " be iMproved, required
filetype off                  " required

" NERD Tree 
let g:NERDTreeDirArrows = 1
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'

" Setting up Vundle - the vim plugin bundler
let iCanHazVundle=1
let vundle_readme=expand('~/.vim/bundle/Vundle.vim/README.md')
if !filereadable(vundle_readme) 
	echo "Installing Vundle.."
	echo ""
	silent !mkdir -p ~/.vim/bundle
	silent !git clone https://github.com/VundleVim/Vundle.vim ~/.vim/bundle/Vundle.vim
	let iCanHazVundle=0
endif

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
" Add all of your Plugins here
Plugin 'altercation/vim-colors-solarized' "T-H-E colorscheme
Plugin 'https://github.com/tpope/vim-fugitive' "So awesome, it should be illegal 
Plugin 'https://github.com/scrooloose/nerdtree' "THE NERD TREE
Plugin 'kien/ctrlp.vim' "Fuzzy searcher
Plugin 'scrooloose/nerdcommenter' "NERD Commenter
Plugin 'airblade/vim-gitgutter' "GitGutter
Plugin 'fatih/vim-go' "Go support
Plugin 'ervandew/supertab' "Tab completion insertion
Plugin 'derekwyatt/vim-scala' "Scala support
Plugin 'https://github.com/bling/vim-airline' "Light weight status bar
" All of your Plugins must be added before the following line
if iCanHazVundle == 0
	echo "Installing Vundles, please ignore key map error messages"
	echo ""
	:VundleInstall
endif
" Setting up Vundle - the vim plugin bundler end
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
