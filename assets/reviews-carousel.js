(function () {
    var cfg = window.SITE_CONFIG;
    if (!cfg || !cfg.reviews || !cfg.reviews.length) return;

    var widgets = document.querySelectorAll('[data-reviews-carousel]');
    if (!widgets.length) return;

    var prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    function slidesPerView() {
        if (window.innerWidth >= 1024) return 3;
        if (window.innerWidth >= 640) return 2;
        return 1;
    }

    function initials(name) {
        return name.replace(/[^A-Za-zÀ-ÿ\s]/g, '').trim().charAt(0).toUpperCase() || '?';
    }

    function stars(n) {
        var s = '';
        for (var i = 0; i < 5; i++) s += i < n ? '★' : '☆';
        return s;
    }

    widgets.forEach(function (root) {
        var track = root.querySelector('.reviews-widget__track');
        var dotsWrap = root.querySelector('.reviews-widget__dots');
        var btnPrev = root.querySelector('.reviews-widget__btn--prev');
        var btnNext = root.querySelector('.reviews-widget__btn--next');
        if (!track) return;

        track.innerHTML = '';
        cfg.reviews.forEach(function (review) {
            var slide = document.createElement('div');
            slide.className = 'reviews-widget__slide';
            slide.innerHTML =
                '<article class="reviews-widget__card">' +
                    '<div class="reviews-widget__card-top">' +
                        '<div class="reviews-widget__avatar" aria-hidden="true">' + initials(review.name) + '</div>' +
                        '<div>' +
                            '<p class="reviews-widget__meta-name">' + review.name + '</p>' +
                            '<p class="reviews-widget__meta-date">' + review.date + '</p>' +
                        '</div>' +
                    '</div>' +
                    '<div class="reviews-widget__card-stars" aria-label="' + review.stars + ' de 5 estrelas">' + stars(review.stars) + '</div>' +
                    '<p class="reviews-widget__card-text">"' + review.text + '"</p>' +
                '</article>';
            track.appendChild(slide);
        });

        var current = 0;
        var timer = null;
        var total = cfg.reviews.length;

        function maxIndex() {
            return Math.max(0, total - slidesPerView());
        }

        function renderDots() {
            if (!dotsWrap) return;
            dotsWrap.innerHTML = '';
            var pages = maxIndex() + 1;
            for (var i = 0; i < pages; i++) {
                var dot = document.createElement('button');
                dot.type = 'button';
                dot.className = 'reviews-widget__dot' + (i === current ? ' is-active' : '');
                dot.setAttribute('aria-label', 'Ir para avaliação ' + (i + 1));
                dot.dataset.index = String(i);
                dotsWrap.appendChild(dot);
            }
        }

        function goTo(index) {
            current = Math.max(0, Math.min(index, maxIndex()));
            var pct = (current * 100) / slidesPerView();
            track.style.transform = 'translateX(-' + pct + '%)';
            if (dotsWrap) {
                dotsWrap.querySelectorAll('.reviews-widget__dot').forEach(function (d, i) {
                    d.classList.toggle('is-active', i === current);
                });
            }
        }

        function next() { goTo(current >= maxIndex() ? 0 : current + 1); }
        function prev() { goTo(current <= 0 ? maxIndex() : current - 1); }

        function startAutoplay() {
            stopAutoplay();
            if (prefersReduced) return;
            timer = setInterval(next, 5000);
        }

        function stopAutoplay() {
            if (timer) { clearInterval(timer); timer = null; }
        }

        renderDots();
        goTo(0);

        if (btnNext) btnNext.addEventListener('click', function () { next(); startAutoplay(); });
        if (btnPrev) btnPrev.addEventListener('click', function () { prev(); startAutoplay(); });
        if (dotsWrap) {
            dotsWrap.addEventListener('click', function (e) {
                var btn = e.target.closest('.reviews-widget__dot');
                if (!btn) return;
                goTo(parseInt(btn.dataset.index, 10));
                startAutoplay();
            });
        }

        root.addEventListener('mouseenter', stopAutoplay);
        root.addEventListener('mouseleave', startAutoplay);

        window.addEventListener('resize', function () {
            renderDots();
            goTo(Math.min(current, maxIndex()));
        });

        startAutoplay();
    });
})();
